import ComposableArchitecture

extension AppReducer {
  @Reducer
  struct StackReducer {
    enum State: Equatable {
      case folder(FolderReducer.State)
      case recipe(RecipeReducer.State)
    }
    
    enum Action: Equatable {
      case folder(FolderReducer.Action)
      case recipe(RecipeReducer.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: \.folder, action: \.folder, child: FolderReducer.init)
      Scope(state: \.recipe, action: \.recipe, child: RecipeReducer.init)
    }
  }
}
