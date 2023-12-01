import ComposableArchitecture

@Reducer
struct AppReducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    var stack = StackState<StackReducer.State>()
    var rootFolders = RootFoldersReducer.State()
  }
  
  enum Action: Equatable {
    case task
    case didLoad
    case stack(StackAction<StackReducer.State, StackReducer.Action>)
    case rootFolders(RootFoldersReducer.Action)
  }
  
  @Dependency(\.database) var database
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(state: \.rootFolders, action: \.rootFolders) {
      RootFoldersReducer()
    }
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
      case .task:
        return .run { send in
          await database.initializeDatabase()
          await send(.didLoad)
        }
        
      case .didLoad:
        state.loadStatus = .didLoad
        return .none
        
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
          let rf = state.rootFolders
          return switch delegateAction {
          case let .addNewFolderDidComplete(childID):
              .folder(.init(folderID: rf.userFolders[id: childID]!.id))
          case let .addNewRecipeDidComplete(childID):
              .recipe(.init(recipeID: rf.systemFolders[id: rf.systemStandardFolderID]!.recipes[id: childID]!.id))
          case let .userFolderTapped(childID):
              .folder(.init(folderID: rf.userFolders[id: childID]!.id))
          case let .systemFolderTapped(childID):
              .folder(.init(folderID: rf.systemFolders[id: childID]!.id))
          }
        }() {
          state.stack.append(newStackElement)
        }
        return .none
        
      case .rootFolders, .stack:
        return .none
      }
    }
    .forEach(\.stack, action: \.stack, destination: StackReducer.init)
    .signpost()
  }
}
