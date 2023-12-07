import ComposableArchitecture

extension AppReducer {
  struct StackReducer: Reducer {
    enum State: Equatable {
      case folder(FolderReducer.State)
      case recipe(RecipeReducer.State)
    }
    
    enum Action: Equatable {
      case folder(FolderReducer.Action)
      case recipe(RecipeReducer.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: /StackReducer.State.folder, action: /StackReducer.Action.folder) {
        FolderReducer()
      }
      Scope(state: /StackReducer.State.recipe, action: /StackReducer.Action.recipe) {
        RecipeReducer()
      }
    }
  }
}
