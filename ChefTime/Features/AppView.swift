import SwiftUI
import ComposableArchitecture

// MARK: - View
struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.path, action: AppReducer.Action.path)) {
        FoldersView(store: store.scope(state: \.folders, action: AppReducer.Action.folders))
      } destination: { state in
        switch state {
        case .folder:
          CaseLet(
            /AppReducer.PathReducer.State.folder,
             action: AppReducer.PathReducer.Action.folder,
             then: FolderView.init(store:)
          )
        case .recipe:
          CaseLet(
            /AppReducer.PathReducer.State.recipe,
             action: AppReducer.PathReducer.Action.recipe,
             then: RecipeView.init(store:)
          )
        }
      }
    }
  }
}

// MARK: - Reducer
struct AppReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var folders = FoldersReducer.State()
  }
  
  enum Action: Equatable {
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case folders(FoldersReducer.Action)
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    Scope(state: \.folders, action: /Action.folders) {
      FoldersReducer()
    }
    Reduce { state, action in
      switch action {
        
      case let .path(.element(id: id, action: .folder(action))):
        return .none
        
      case let .path(.element(id: id, action: .recipe(action))):
        return .none
        
        // Folders.UserFolders tapped a folder.
      case let .folders(.userFoldersSection(.delegate(.folderTapped(id)))):
        guard let folder = state.folders.userFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        
        // Folders.SystemFolders tapped a folder
      case let .folders(.systemFoldersSection(.delegate(.folderTapped(id)))):
        guard let folder = state.folders.systemFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        
        // Folders created a new folder (can only create a user folder)
      case let .folders(.delegate(.addNewFolderButtonTappedDidComplete(id))):
        guard let folder = state.folders.userFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        
        // Folders created a new folder (will only add one to the standard folder)
      case let .folders(.delegate(.addNewRecipeButtonTappedDidComplete(id))):
        guard let recipe = state.folders.systemFoldersSection.folders[1].folder.recipes[id: id]
        else { return .none }
        return navigateToRecipe(state: &state, recipe: .init(recipe: recipe))
  
        
      case .path, .folders:
        return .none
      }
    }
    .forEach(\.path, action: /Action.path) {
      PathReducer()
    }
  }
}

// MARK: - Shared Reducer Logic
extension AppReducer {
  func navigateToFolder(state: inout State, folder: FolderGridItemReducer.State) -> Effect<Action> {
    state.path.append(.folder(.init(
      name: folder.folder.name,
      folders: .init(title: "Folders", folders: .init(uniqueElements: folder.folder.folders.map {
        .init(id: .init(rawValue: uuid()), folder: $0)
      })),
      recipes: .init(title: "Recipes", recipes: .init(uniqueElements: folder.folder.recipes.map {
        .init(id: .init(rawValue: uuid()), recipe: $0)
      }))
    )))
    return .none
  }
  
  func navigateToRecipe(state: inout State, recipe: RecipeReducer.State) -> Effect<Action> {
    state.path.append(.recipe(recipe))
    return .none
  }
}

// MARK: - PathReducer
extension AppReducer {
  struct PathReducer: Reducer {
    enum State: Equatable {
      case folder(FolderReducer.State)
      case recipe(RecipeReducer.State)
    }
    
    enum Action: Equatable {
      case folder(FolderReducer.Action)
      case recipe(RecipeReducer.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: /State.folder, action: /Action.folder) {
        FolderReducer()
      }
      Scope(state: /State.recipe, action: /Action.recipe) {
        RecipeReducer()
      }
    }
  }
}

// MARK: - Preview
struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: .init(
      initialState: .init(),
      reducer: AppReducer.init
    ))
  }
}

