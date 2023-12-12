import ComposableArchitecture

struct AppReducer: Reducer {
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
    Scope(state: \.rootFolders, action: /AppReducer.Action.rootFolders) {
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
        
      case let .stack(.element(_, action: .folder(.delegate(.navigateToFolder(id))))):
        state.stack.append(.folder(.init(folderID: id)))
        return .none
        
      case let .stack(.element(_, action: .folder(.delegate(.navigateToRecipe(id))))):
        state.stack.append(.recipe(.init(recipeID: id)))
        return .none
        
      case let .rootFolders(.delegate(.navigateToFolder(id))):
        state.stack.append(.folder(.init(folderID: id)))
        return .none
        
      case let .rootFolders(.delegate(.navigateToRecipe(id))):
        state.stack.append(.recipe(.init(recipeID: id)))
        return .none
        
      case .rootFolders, .stack:
        return .none
      }
    }
    .forEach(\.stack, action: /AppReducer.Action.stack) {
      StackReducer()
    }
    .signpost()
  }
}
