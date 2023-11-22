import ComposableArchitecture

@Reducer
struct RecipeSectionReducer {
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
    case recipes(IdentifiedActionOf<RecipeGridItemReducer>)
    case binding(BindingAction<State>)
    
    case delegate(DelegateAction)
    @CasePathable
    @dynamicMemberLookup
    enum DelegateAction: Equatable {
      case recipeTapped(RecipeGridItemReducer.State.ID)
    }
  }
  
  var body: some Reducer<State, Action> {
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
        
      case let .recipes(.element(id: id, action: .delegate(action))):
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
    .forEach(\.recipes, action: \.recipes, element: RecipeGridItemReducer.init)
  }
}
