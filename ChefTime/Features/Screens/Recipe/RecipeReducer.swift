import ComposableArchitecture
import Tagged

struct RecipeReducer: Reducer {
  struct State: Equatable {
    var recipe: Recipe
    var photos: PhotosReducer.State
    var about: AboutListReducer.State
    var ingredients: IngredientsListReducer.State
    var steps: StepListReducer.State
    var isHidingImages: Bool
    @BindingState var navigationTitle: String
    @PresentationState var alert: AlertState<AlertAction>?
    
    
    init(recipeID: Recipe.ID) {
      self.init(recipe: .init(id: recipeID))
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
    case recipeUpdate(RecipeUpdateAction)
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
        case .task:
          let recipe = state.recipe
          return .run { send in
            // TODO: Might be wise to check if the ID here matches...
            if let newRecipe = await self.database.retrieveRecipe(recipe.id) {
              await send(.fetchRecipeSuccess(newRecipe))
            }
            else {
              await self.database.createRecipe(recipe)
            }
          }
          
        case let .fetchRecipeSuccess(newRecipe):
          state = .init(recipe: newRecipe)
          return .none
          
        case .binding(\.$navigationTitle):
          // TODO: ... B -> A
          if state.navigationTitle.isEmpty { state.navigationTitle = "Untitled Recipe" }
          state.recipe.name = state.navigationTitle
          return .none
          
        case .recipeUpdate(.photosUpdated):
          state.recipe.imageData = state.photos.photos
          return .none
          
        case .recipeUpdate(.aboutUpdated):
          state.recipe.aboutSections = state.about.recipeSections
          return .none
          
        case .recipeUpdate(.ingredientsUpdated):
          state.recipe.ingredientSections = state.ingredients.recipeSections
          return .none
          
        case .recipeUpdate(.stepsUpdated):
          state.recipe.stepSections = state.steps.recipeSections
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
    .onChange(of: \.photos.photos, { _, _ in
      Reduce { _, _ in
          .send(.recipeUpdate(.photosUpdated))
      }
    })
    .onChange(of: \.about.aboutSections) { _, _ in
      Reduce { _, _ in
          .send(.recipeUpdate(.aboutUpdated))
      }
    }
    .onChange(of: \.ingredients.ingredientSections) { _, _ in
      Reduce { _, _ in
          .send(.recipeUpdate(.ingredientsUpdated))
      }
    }
    .onChange(of: \.steps.stepSections) { _, _ in
      Reduce { _, _ in
          .send(.recipeUpdate(.stepsUpdated))
      }
    }
    .onChange(of: \.recipe) { _, newRecipe in // TODO: Does newRecipe get copied every call?
      Reduce { _, _ in
          .run { _ in
            enum RecipeUpdateID: Hashable { case debounce }
            try await withTaskCancellation(id: RecipeUpdateID.debounce, cancelInFlight: true) {
              try await self.clock.sleep(for: .seconds(1))
              print("Updated recipe \(newRecipe.id.uuidString)")
              await database.updateRecipe(newRecipe)
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
