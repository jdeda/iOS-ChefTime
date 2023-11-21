import ComposableArchitecture

// MARK: - Reducer
struct RecipeSectionReducer: Reducer {
  struct State: Equatable {
    let title: String
    var recipes: IdentifiedArrayOf<RecipeGridItemReducer.State> = []
    @BindingState var isExpanded: Bool = true
    @BindingState var selection = Set<RecipeGridItemReducer.State.ID>()
    
    init(title: String = "Recipes", recipes: IdentifiedArrayOf<Recipe>) {
      self.title = title
      self.recipes = recipes.map({ .init(recipe: $0) })
      self.isExpanded = true
      self.selection = []
    }
  }
  
  enum Action: Equatable, BindableAction {
    case recipeSelected(RecipeGridItemReducer.State.ID)
    case recipes(RecipeGridItemReducer.State.ID, RecipeGridItemReducer.Action)
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .recipeSelected(id):
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        
        return .none
        
      case let .recipes(id, .delegate(action)):
        switch action {
        case .move:
          break
        case .delete:
          state.recipes.remove(id: id)
          break
        }
        return .none
        
        
      case .recipes, .binding, .delegate:
        return .none
      }
    }
    .forEach(\.recipes, action: /Action.recipes) {
      RecipeGridItemReducer()
    }
    
  }
}

// MARK: - DelegateAction
extension RecipeSectionReducer {
  enum DelegateAction: Equatable {
    case recipeTapped(RecipeGridItemReducer.State.ID)
  }
}
