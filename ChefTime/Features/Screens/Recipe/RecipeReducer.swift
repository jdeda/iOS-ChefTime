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
@Reducer
struct RecipeReducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    var isLoading = false
    var recipe: Recipe
    var photos: PhotosReducer.State {
      didSet { self.recipe.imageData = self.photos.photos }
    }
    var about: AboutListReducer.State {
      didSet { self.recipe.stepSections = steps.recipeSections }
    }
    var ingredients: IngredientsListReducer.State {
      didSet { self.recipe.stepSections = steps.recipeSections }
    }
    var steps: StepListReducer.State {
      didSet { self.recipe.stepSections = steps.recipeSections }
    }
    var isHidingImages: Bool
    @BindingState var navigationTitle: String
    @PresentationState var alert: AlertState<Action.AlertAction>?
    
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
    
    var isHidingPhotosView: Bool {
      if self.isHidingImages {
        return true
      }
      else if !self.photos.photos.isEmpty {
        return false
      }
      else {
        return !(self.photos.photoEditStatus == .addWhenEmpty && self.photos.photoEditInFlight)
      }
    }
  }
  
  enum Action: Equatable, BindableAction {
    case didLoad
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
    @CasePathable
    @dynamicMemberLookup
    enum AlertAction: Equatable {
      case confirmDeleteSectionButtonTapped(Section)
    }
  }

  @CasePathable
  enum Section: Equatable {
    case photos
    case about
    case ingredients
    case steps
  }
  
  @CasePathable
  enum SectionEditAction: Equatable {
    case add
    case delete
  }

  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  @Dependency(\.database) var database
  
  var body: some Reducer<RecipeReducer.State, RecipeReducer.Action> {
    CombineReducers {
      Scope(state: \.photos, action: \.photos, child: PhotosReducer.init)
      Scope(state: \.about, action: \.about, child: AboutListReducer.init)
      Scope(state: \.ingredients, action: \.ingredients, child: IngredientsListReducer.init)
      Scope(state: \.steps, action: \.steps, child: StepListReducer.init)
      BindingReducer()
      Reduce<RecipeReducer.State, RecipeReducer.Action> { state, action in
        switch action {
        case .didLoad:
          state.loadStatus = .didLoad
          return .none
          
        case .task:
          guard state.loadStatus == .didNotLoad else { return .none }
          state.loadStatus = .isLoading
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
            await send(.didLoad)
          }
          
        case let .fetchRecipeSuccess(newRecipe):
          state = .init(recipe: newRecipe)
          return .none
          
        case .binding(\.$navigationTitle):
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
            case .photos: state.alert = .deletePhotos
            case .about: state.alert = .deleteAbout
            case .ingredients: state.alert = .deleteIngredients
            case .steps: state.alert = .deleteSteps
            }
            return .none
            
          case .add:
            switch section {
            case .photos:
              state.photos = .init(photos: [])
              state.photos.photoEditStatus = .addWhenEmpty
              state.photos.photoPickerIsPresented = true
            case .about:
              state.about = .init(recipeSections: [])
              state.about.aboutSections.append(.init(
                aboutSection: .init(id: .init(rawValue: uuid())),
                focusedField: .description
              ))
            case .ingredients:
              state.ingredients = .init(recipeSections: [])
              let ingredient = Recipe.IngredientSection.Ingredient(id: .init(rawValue: uuid()))
              let ingredientSection = Recipe.IngredientSection(
                id: .init(rawValue: uuid()),
                ingredients: [ingredient]
              )
              state.ingredients.ingredientSections.append(.init(ingredientSection: ingredientSection))
              state.ingredients.ingredientSections[id: ingredientSection.id]!
                .ingredients[id: ingredient.id]!
                .focusedField = .name
            case .steps:
              state.steps = .init(recipeSections: [])
              let step = Recipe.StepSection.Step(id: .init(rawValue: uuid()))
              let stepSection = Recipe.StepSection(
                id: .init(rawValue: uuid()),
                steps: [step]
              )
              state.steps.stepSections.append(.init(stepSection: stepSection))
              state.steps.stepSections[id: stepSection.id]!
                .steps[id: step.id]!
                .focusedField = .description
            }
            return .none
          }
          
        case let .alert(.presented(.confirmDeleteSectionButtonTapped(section))):
          // Reset the states to make sure all in-flight effects are cancelled
          // and be sure to collapse everything while deleting for nice animations.
          switch section {
          case .photos:
            state.photos = .init(photos: [])
          case .about:
            state.about = .init(recipeSections: [])
            state.about.isExpanded = false
            state.about.aboutSections.ids.forEach {
              state.about.aboutSections[id: $0]?.isExpanded = false
            }
            
          case .ingredients:
            state.ingredients = .init(recipeSections: [])
            state.ingredients.isExpanded = false
            state.ingredients.ingredientSections.ids.forEach {
              state.ingredients.ingredientSections[id: $0]?.isExpanded = false
            }
            
          case .steps:
            state.steps = .init(recipeSections: [])
            state.steps.isExpanded = false
            state.steps.stepSections.ids.forEach {
              state.steps.stepSections[id: $0]?.isExpanded = false
            }
          }
          state.alert = nil
          return .none
          
        case .alert(.dismiss):
          state.alert = nil
          return .none
          
        case .photos(.deleteButtonTapped):
          if state.photos.photos.count == 1 {
            // hide, then delete
            
          }
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
    .signpost()
  }
}

extension AlertState where Action == RecipeReducer.Action.AlertAction {
  static let deletePhotos = Self(
    title: {
      TextState("Delete Photos")
    },
    actions: {
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.photos), animation: .default)
      ){
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
  static let deleteAbout = Self(
    title: {
      TextState("Delete About")
    },
    actions: {
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.about), animation: .default)
      ){
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
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.ingredients), animation: .default)
      ){
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
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.steps), animation: .default)
      ){
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
