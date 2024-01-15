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
          state.stack[id: lastID] = .folder(.init(folderID: folder.folder.id, folderName: folder.folder.name))
          return .send(.stack(.element(id: lastID, action: .folder(.task))))
          
        case let .recipe(recipe): // We want to refresh the data.
          let lastID = state.stack.ids.last!
          // TODO: You don't want to clear ALL the state. You'd want to cancel all effects, reset the recipe or folder then call .task
          state.stack[id: lastID] = .recipe(.init(recipeID: recipe.recipe.id, recipeName: recipe.recipe.name))
          return .send(.stack(.element(id: lastID, action: .folder(.task))))
          
        case .none: // We are an empty stack now, // We want to refresh the data.
          state.rootFolders = .init()
          return .send(.rootFolders(.task))
        }
        
        
      case let .rootFolders(.delegate(.navigateToFolder(id, name))):
        // Make sure animation is smooth and we get completely refreshed view with a loading screen.
        state.rootFolders.loadStatus = .isLoading
        state.stack.append(.folder(.init(folderID: id, folderName: name)))  // Add the drilldown.
        return .none
        
      case let .rootFolders(.delegate(.navigateToRecipe(id, name))):
        state.rootFolders.loadStatus = .isLoading
        state.stack.append(.recipe(.init(recipeID: id, recipeName: name)))
        return .none
        
      case let .stack(.element(stackID, action: .folder(.delegate(.navigateToFolder(id, name))))):
        // Make sure animation is smooth and we get completely refreshed view with a loading screen.
        let oldFolder = (/StackReducer.State.folder).extract(from: state.stack[id: stackID])!.folder
        var newFolder = FolderReducer.State(folderID: oldFolder.id, folderName: oldFolder.name)
        newFolder.loadStatus = .isLoading
        state.stack[id: stackID] = .folder(newFolder)
        state.stack.append(.folder(.init(folderID: id, folderName: name))) // Add the drilldown.
        return .none
        
      case let .stack(.element(stackID, action: .folder(.delegate(.navigateToRecipe(id, name))))):
        // Make sure animation is smooth and we get completely refreshed view with a loading screen.
        let oldFolder = (/StackReducer.State.folder).extract(from: state.stack[id: stackID])!.folder
        var newFolder = FolderReducer.State(folderID: oldFolder.id, folderName: oldFolder.name)
        newFolder.loadStatus = .isLoading
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
