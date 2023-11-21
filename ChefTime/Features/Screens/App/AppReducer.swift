import ComposableArchitecture

@Reducer
struct AppReducer {
  struct State: Equatable {
    var stack = StackState<StackReducer.State>()
    var folders = FoldersReducer.State()
  }
  
  enum Action: Equatable {
    case stack(StackAction<StackReducer.State, StackReducer.Action>)
    case folders(FoldersReducer.Action)
  }
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(state: \.folders, action: \.folders, child: FoldersReducer.init)
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
        
      case let .folders(.delegate(delegateAction)):
        // TODO: Remove force unwraps before production.
        if let newStackElement: StackReducer.State = {
          switch delegateAction {
          case let .addNewFolderDidComplete(childID):
              .folder(.init(folderID: state.folders.userFoldersSection.folders[id: childID]!.id))
          case let .addNewRecipeDidComplete(childID):
              .recipe(.init(recipeID: state.folders.systemFoldersSection.folders.first(where: {
                $0.folder.folderType == .systemStandard
              })!.folder.recipes[id: childID]!.id))
          case let .userFolderTapped(childID):
              .folder(.init(folderID: state.folders.userFoldersSection.folders[id: childID]!.id))
          case let .systemFolderTapped(childID):
              .folder(.init(folderID: state.folders.systemFoldersSection.folders[id: childID]!.id))
          }
        }() {
          state.stack.append(newStackElement)
        }
        return .none
        
      case .folders, .stack:
        return .none
      }
    }
    ._printChanges()
    .forEach(\.stack, action: \.stack, destination: StackReducer.init)
  }
}
