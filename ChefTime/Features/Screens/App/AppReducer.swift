import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    var stack = StackState<StackReducer.State>()
    var rootFolders = RootFoldersReducer.State()
    
    init(
      loadStatus: LoadStatus = .didNotLoad,
      stack: StackState<StackReducer.State> = .init()
    ) {
      self.loadStatus = loadStatus
      self.stack = stack
      self.rootFolders = .init()
      self.rootFolders.loadStatus = .isLoading
    }
  }
  
  enum Action: Equatable {
    case task
    case didLoad([Folder])
    case stack(StackAction<StackReducer.State, StackReducer.Action>)
    case rootFolders(RootFoldersReducer.Action)
  }
  
  @Dependency(\.database) var database
  @Dependency(\.continuousClock) var clock
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(state: \.rootFolders, action: /AppReducer.Action.rootFolders) {
      RootFoldersReducer()
    }
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
      case .task:
        return .run { send in
          await database.initializeDatabase()
          let rootFolders = await self.database.retrieveRootFolders()
          await send(.didLoad(rootFolders))
        }
        
      case let .didLoad(folders):
        state.loadStatus = .didLoad
        state.rootFolders = .init(userFolders: .init(uniqueElements: folders))
        state.rootFolders.loadStatus = .didLoad
        return .none
        
      case let .stack(.popFrom(id)):
        state.stack.pop(from: id)
        if state.stack.isEmpty {
          state.rootFolders.loadStatus = .didNotLoad
          return .send(.rootFolders(.task))
        }
        return .none
        
        
      case let .rootFolders(.delegate(.navigateToFolder(id))):
        state.rootFolders.loadStatus = .isLoading
        state.stack.append(.folder(.init(folderID: id)))
        return .none
        
      case let .rootFolders(.delegate(.navigateToRecipe(id))):
        state.rootFolders.loadStatus = .isLoading
        state.stack.append(.recipe(.init(recipeID: id)))
        return .none
        
      case let .stack(.element(_, action: .folder(.delegate(.navigateToFolder(id))))):
        state.stack.append(.folder(.init(folderID: id)))
        return .none
        
      case let .stack(.element(_, action: .folder(.delegate(.navigateToRecipe(id))))):
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
