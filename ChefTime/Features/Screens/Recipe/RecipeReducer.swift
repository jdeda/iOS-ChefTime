import Foundation
import ComposableArchitecture
import Tagged

/// How to Handle Loading
/// 1. Load Everything Except Images
///   - Based off calculations, keeping the recipes and folders in memory costs nothing, unless you have ten-thousand giant recipes
///     and most people will only have less than one-thousand. Images of course however, can take massive amounts of space, so
///     they must be stored externally (disk or cloud) and only fetched when needed, perhaps with some sort of caching to
///     potentially improve the experience.
/// 2. Load onAppear
///
struct RecipeReducer: Reducer {
  struct State: Equatable {
    var didLoad = false
    var recipe: Recipe
    var photos: PhotosReducer.State {
      didSet {
        self.recipe.imageData = self.photos.photos
      }
    }
    var about: AboutListReducer.State {
      didSet {
        self.recipe.stepSections = steps.recipeSections
      }
    }
    var ingredients: IngredientsListReducer.State {
      didSet {
        self.recipe.stepSections = steps.recipeSections
      }
    }
    var steps: StepListReducer.State {
      didSet {
        self.recipe.stepSections = steps.recipeSections
      }
    }
    var isHidingImages: Bool
    @BindingState var navigationTitle: String
    @PresentationState var alert: AlertState<AlertAction>?
    
    // TODO: - What to do with the dates here?
    init(recipeID: Recipe.ID) {
      self.init(recipe: .init(id: recipeID, creationDate: Date(), lastEditDate: Date()))
    }
    
    init(recipe: Recipe) {
      self.recipe = recipe
      self.photos = .init(photos: recipe.imageData)
      self.about = .init(recipeSections: recipe.aboutSections)
      self.ingredients = .init(recipeSections: recipe.ingredientSections)
      self.steps = .init(recipeSections: recipe.stepSections)
      self.isHidingImages = false
      self.navigationTitle = recipe.name
      self.alert = nil
    }
  }
  
  enum Action: Equatable, BindableAction {
    case setDidLoad(Bool)
    case task
    case fetchRecipeSuccess(Recipe)
    case binding(BindingAction<State>)
    case photos(PhotosReducer.Action)
    case about(AboutListReducer.Action)
    case ingredients(IngredientsListReducer.Action)
    case steps(StepListReducer.Action)
    case toggleHideImages
    case setExpansionButtonTapped(Bool)
    case editSectionButtonTapped(Section, SectionEditAction)
    case alert(PresentationAction<AlertAction>)
  }
  
  @Dependency(\.continuousClock) var clock
  @Dependency(\.database) var database
  
  var body: some Reducer<RecipeReducer.State, RecipeReducer.Action> {
    CombineReducers {
      Scope(state: \.photos, action: /Action.photos) {
        PhotosReducer()
      }
      Scope(state: \.about, action: /Action.about) {
        AboutListReducer()
      }
      Scope(state: \.ingredients, action: /Action.ingredients) {
        IngredientsListReducer()
      }
      Scope(state: \.steps, action: /Action.steps) {
        StepListReducer()
      }
      BindingReducer()
      Reduce<RecipeReducer.State, RecipeReducer.Action> { state, action in
        switch action {
        case let .setDidLoad(didLoad):
          state.didLoad = didLoad
          return .none
          
        case .task:
          guard !state.didLoad else { return .none }
          let recipe = state.recipe
          return .run { send in
            // TODO: Might be wise to check if the ID here matches...
            if let newRecipe = await self.database.retrieveRecipe(recipe.id) {
              await send(.fetchRecipeSuccess(newRecipe))
            }
            else {
              // TODO: - Handle DB errors in future
              try! await self.database.createRecipe(recipe)
            }
          }
          .concatenate(with: .send(.setDidLoad(true)))
          
        case let .fetchRecipeSuccess(newRecipe):
          state = .init(recipe: newRecipe)
          return .none
          
        case .binding(\.$navigationTitle):
          // TODO: ... B -> A
          if state.navigationTitle.isEmpty { state.navigationTitle = "Untitled Recipe" }
          state.recipe.name = state.navigationTitle
          return .none
          
        case .toggleHideImages:
          state.isHidingImages.toggle()
          return .none
          
        case let .setExpansionButtonTapped(isExpanded):
          // TODO: May need to worry about focus state
          
          // Collapse all about sections
          state.about.isExpanded = isExpanded
          state.about.aboutSections.ids.forEach {
            state.about.aboutSections[id: $0]?.isExpanded = isExpanded
          }
          
          // Collapse all ingredient sections
          state.ingredients.isExpanded = isExpanded
          state.ingredients.ingredientSections.ids.forEach {
            state.ingredients.ingredientSections[id: $0]?.isExpanded = isExpanded
          }
          
          // Collapse all step sections
          state.steps.isExpanded = isExpanded
          state.steps.stepSections.ids.forEach {
            state.steps.stepSections[id: $0]?.isExpanded = isExpanded
          }
          return .none
          
        case let .editSectionButtonTapped(section, action):
          switch action {
          case .delete:
            switch section {
            case .about: state.alert = .deleteAbout
            case .ingredients: state.alert = .deleteIngredients
            case .steps: state.alert = .deleteSteps
            }
            return .none
            
          case .add:
            switch section {
            case .about: state.about = .init(recipeSections: [])
            case .ingredients: state.ingredients = .init(recipeSections: [])
            case .steps: state.steps = .init(recipeSections: [])
            }
            return .none
          }
          
        case let .alert(.presented(.confirmDeleteSectionButtonTapped(section))):
          switch section {
          case .about: state.about.aboutSections = []
          case .ingredients: state.ingredients.ingredientSections = []
          case .steps: state.steps.stepSections = []
          }
          state.alert = nil
          return .none
          
        case .alert(.dismiss):
          state.alert = nil
          return .none
          
        case .photos, .about, .ingredients, .steps, .alert, .binding:
          return .none
        }
      }
    }
    .onChange(of: \.recipe) { _, newRecipe in // TODO: Does newRecipe get copied every call?
      Reduce { _, _ in
          .run { _ in
            enum RecipeUpdateID: Hashable { case debounce }
            try await withTaskCancellation(id: RecipeUpdateID.debounce, cancelInFlight: true) {
              try await self.clock.sleep(for: .seconds(1))
              print("Updated recipe \(newRecipe.id.uuidString)")
              // TODO: - Handle DB errors in future
              try! await database.updateRecipe(newRecipe)
            }
          }
      }
    }
  }
}

// MARK: - RecipeUpdateAction
extension RecipeReducer {
  enum RecipeUpdateAction: Equatable {
    case photosUpdated
    case aboutUpdated
    case ingredientsUpdated
    case stepsUpdated
  }
}


// MARK: - AlertAction
extension RecipeReducer {
  enum AlertAction: Equatable {
    case confirmDeleteSectionButtonTapped(Section)
  }
}


// MARK: - AlertState
extension AlertState where Action == RecipeReducer.AlertAction {
  static let deleteAbout = Self(
    title: {
      TextState("Delete About")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSectionButtonTapped(.about)){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteIngredients = Self(
    title: {
      TextState("Delete Ingredients")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSectionButtonTapped(.ingredients)){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteSteps = Self(
    title: {
      TextState("Delete Steps")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSectionButtonTapped(.steps)){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
}


// MARK: - Section Helper
extension RecipeReducer {
  enum Section: Equatable {
    case about
    case ingredients
    case steps
  }
  
  enum SectionEditAction: Equatable {
    case add
    case delete
  }
}
