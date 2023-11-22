import ComposableArchitecture

@Reducer
struct AppReducer {
  struct State: Equatable {
    var stack = StackState<StackReducer.State>()
    var rootFolders = RootFoldersReducer.State()
  }
  
  enum Action: Equatable {
    case stack(StackAction<StackReducer.State, StackReducer.Action>)
    case rootFolders(RootFoldersReducer.Action)
  }
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(
      state: \.rootFolders,
      action: \.rootFolders,
      child: RootFoldersReducer.init
    )
    
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
      case let .stack(.element(id: id, action: .folder(.delegate(delegateAction)))):
        // TODO: Remove force unwraps before production.
        let folder = state.stack[id: id]!.folder!.folder
        if let newStackElement: StackReducer.State = {
          switch delegateAction {
          case let .addNewFolderDidComplete(childID):
             .folder(.init(folderID: folder.folders[id: childID]!.id))
          case let .addNewRecipeDidComplete(childID):
             .recipe(.init(recipeID: folder.recipes[id: childID]!.id))
          case let .folderTapped(childID):
             .folder(.init(folderID: folder.folders[id: childID]!.id))
          case let .recipeTapped(childID):
             .recipe(.init(recipeID: folder.recipes[id: childID]!.id))
          case .folderUpdated:
             nil
          }
        }() {
          state.stack.append(newStackElement)
        }
        return .none
        
      case let .rootFolders(.delegate(delegateAction)):
        // TODO: Remove force unwraps before production.
        if let newStackElement: StackReducer.State = {
          switch delegateAction {
          case let .addNewFolderDidComplete(childID):
              .folder(.init(folderID: state.rootFolders.userFoldersSection.folders[id: childID]!.id))
          case let .addNewRecipeDidComplete(childID):
              .recipe(.init(recipeID: state.rootFolders.systemFoldersSection.folders.first(where: {
                $0.folder.folderType == .systemStandard
              })!.folder.recipes[id: childID]!.id))
          case let .userFolderTapped(childID):
              .folder(.init(folderID: state.rootFolders.userFoldersSection.folders[id: childID]!.id))
          case let .systemFolderTapped(childID):
              .folder(.init(folderID: state.rootFolders.systemFoldersSection.folders[id: childID]!.id))
          }
        }() {
          state.stack.append(newStackElement)
        }
        return .none
        
      case .rootFolders, .stack:
        return .none
      }
    }
    ._printChanges()
    .forEach(\.stack, action: \.stack, destination: StackReducer.init)
  }
}
