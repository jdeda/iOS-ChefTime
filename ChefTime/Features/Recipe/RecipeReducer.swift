import ComposableArchitecture
import Tagged

struct RecipeReducer: Reducer {
  struct State: Equatable {
    // this is what powers this feature
    @BindingState var navigationTitle: String
    var recipe: Recipe
    var photos: PhotosReducer.State
    var about: AboutListReducer.State
    var ingredients: IngredientsListReducer.State
    var steps: StepListReducer.State
    var isHidingImages: Bool
    @PresentationState var alert: AlertState<AlertAction>?
    
    init(recipe: Recipe) {
      self.navigationTitle = recipe.name
      self.recipe = recipe
      self.photos = .init(photos: recipe.imageData)
      
      // A to B
      self.about = .init(recipeSections: recipe.aboutSections)
      self.ingredients = .init(recipeSections: recipe.ingredientSections)
      self.steps = .init(recipeSections: recipe.stepSections)
      self.isHidingImages = false
      // Abuse of typed IDs
      // Ugly ceremony of identified array (well u can write a map to clean it 100X)
      // Ugly ceremony of creating a feature that should just be init with persistent model
      // Combining these things makes the feature very ugly, but an easy fix :D
      // Not syncing feature to persistent model
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case photos(PhotosReducer.Action)
    case about(AboutListReducer.Action)
    case ingredients(IngredientsListReducer.Action)
    case steps(StepListReducer.Action)
    case toggleHideImages
    case setExpansionButtonTapped(Bool)
    case editSectionButtonTapped(Section, SectionEditAction)
    case alert(PresentationAction<AlertAction>)
    
    enum DelegateAction: Equatable {
      case recipeUpdated(RecipeReducer.State)
    }
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .binding(\.$navigationTitle):
        if state.navigationTitle.isEmpty { state.navigationTitle = "Untitled Recipe" }
        state.recipe.name = state.navigationTitle
        return .none

//      case .about(.recipeSectionsDidChange):
//        print(".about(.recipeSectionsDidChange)")
//
//        // this is the B to A, from the previous discussion
//        if let recipeSections = state.about?.recipeSections {
//          print("recipeSections: '\(recipeSections)'")
//          state.recipe.aboutSections = recipeSections
//        }
//        return .none

      case .about:
        return .none
        
      case .photos, .ingredients, .steps:
        // TODO: fix me ...
        print("recipeSections: 'NOOP'")
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

      case .alert, .delegate:
        return .none
      }
    }
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
