import ComposableArchitecture

// Right now, loading screens are plaging this app.
// We would love to seamlessly drill in and out of views, without having to pause and load things.
// However, I notice that the NavigationStack is awfully slow.
// None of the work happens mid-flight of the stack animation backing out.
// It only begins when the back out animation ends.
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
        switch state.stack.last {
        case let .folder(folder): // We want to refresh the data.
          let lastID = state.stack.ids.last!
          let fdsOld = (/StackReducer.State.folder).extract(from: state.stack[id: lastID])!
          var fds = FolderReducer.State(folderID: folder.folder.id, folderName: folder.folder.name)
          fds.search = fdsOld.search // Keep search state.
          state.stack[id: lastID] = .folder(fds)
          return .send(.stack(.element(id: lastID, action: .folder(.task))))
          
        case let .recipe(recipe): // We want to refresh the data.
          let lastID = state.stack.ids.last!
          state.stack[id: lastID] = .recipe(.init(recipeID: recipe.recipe.id, recipeName: recipe.recipe.name))
          return .send(.stack(.element(id: lastID, action: .folder(.task))))
          
        case .none: // We are an empty stack now, // We want to refresh the data.
          let oldSearchState = state.rootFolders.search
          state.rootFolders = .init()
          state.rootFolders.search = oldSearchState
          return .send(.rootFolders(.task))
        }
        
        
      case let .rootFolders(.delegate(.navigateToFolder(id, name))):
        // Make sure animation is smooth and we get completely refreshed view with a loading screen.
        let oldSearchState = state.rootFolders.search
        state.rootFolders = .init()
        state.rootFolders.loadStatus = .isLoading
        state.rootFolders.search = oldSearchState
        state.stack.append(.folder(.init(folderID: id, folderName: name)))  // Add the drilldown.
        return .none
        
      case let .rootFolders(.delegate(.navigateToRecipe(id, name))):
        let oldSearchState = state.rootFolders.search
        state.rootFolders = .init()
        state.rootFolders.loadStatus = .isLoading
        state.rootFolders.search = oldSearchState
        state.stack.append(.recipe(.init(recipeID: id, recipeName: name)))
        return .none
        
      case let .stack(.element(stackID, action: .folder(.delegate(.navigateToFolder(id, name))))):
        // Make sure animation is smooth and we get completely refreshed view with a loading screen.
        // You must clear the state before to get proper animation.
        let oldFolder = (/StackReducer.State.folder).extract(from: state.stack[id: stackID])!
        var newFolder = FolderReducer.State(folderID: oldFolder.folder.id, folderName: oldFolder.folder.name)
        newFolder.loadStatus = .isLoading
        newFolder.search = oldFolder.search
        state.stack[id: stackID] = .folder(newFolder)
        state.stack.append(.folder(.init(folderID: id, folderName: name))) // Add the drilldown.
        return .none
        
      case let .stack(.element(stackID, action: .folder(.delegate(.navigateToRecipe(id, name))))):
        // Make sure animation is smooth and we get completely refreshed view with a loading screen.
        // You must clear the state before to get proper animation.
        let oldFolder = (/StackReducer.State.folder).extract(from: state.stack[id: stackID])!
        var newFolder = FolderReducer.State(folderID: oldFolder.folder.id, folderName: oldFolder.folder.name)
        newFolder.loadStatus = .isLoading
        newFolder.search = oldFolder.search
        state.stack[id: stackID] = .folder(newFolder)
        state.stack.append(.recipe(.init(recipeID: id, recipeName: name)))  // Add the drilldown.
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
