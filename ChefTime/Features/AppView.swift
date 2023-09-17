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
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(state: \.folders, action: /Action.folders) {
      FoldersReducer()
    }
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
        
        // Folder taps into a folder.
      case let .path(.element(id: pathID, action: .folder(.folders(.delegate(.folderTapped(id)))))):
        return folderNavigateToFolder(state: &state, pathID: pathID, id: id)
        
        // Folder taps into a recipe.
      case let .path(.element(id: pathID, action: .folder(.recipes(.delegate(.recipeTapped(id)))))):
        return folderNavigateToRecipe(state: &state, pathID: pathID, id: id)
        
        // Folder creates a new folder.
      case let .path(.element(id: pathID, action: .folder(.delegate(.addNewFolderButtonTappedDidComplete(id))))):
        return folderNavigateToFolder(state: &state, pathID: pathID, id: id)
        
        // Folder creates a new recipe.
      case let .path(.element(id: pathID, action: .folder(.delegate(.addNewRecipeButtonTappedDidComplete(id))))):
        return folderNavigateToRecipe(state: &state, pathID: pathID, id: id)
        
        // Folders.UserFolders taps into a folder.
      case let .folders(.userFoldersSection(.delegate(.folderTapped(id)))):
        guard let folder = state.folders.userFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        
        // Folders.SystemFolders taps into a folder
      case let .folders(.systemFoldersSection(.delegate(.folderTapped(id)))):
        guard let folder = state.folders.systemFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        
        // Folders creates a new folder (can only create a user folder)
      case let .folders(.delegate(.addNewFolderButtonTappedDidComplete(id))):
        guard let folder = state.folders.userFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        
        // Folders creates a new folder (will only add one to the standard folder)
      case let .folders(.delegate(.addNewRecipeButtonTappedDidComplete(id))):
        guard let recipe = state.folders.systemFoldersSection.folders[1].folder.recipes[id: id]
        else { return .none }
        return navigateToRecipe(state: &state, recipe: .init(recipe: recipe))
        

      case let .path(.popFrom(id: id)):
        switch state.path[id: id] {
        case let .folder(folder):
          let isEmpty = folder.folders.folders.isEmpty && folder.recipes.recipes.isEmpty
          // TODO: Delete this folder because it is empty, and propagate all changes to its elders
          return .none
          
        case let .recipe(recipe):
          let isEmpty = recipe.photos.photos.isEmpty &&
          recipe.about?.aboutSections.isEmpty ?? false  &&
          recipe.ingredients?.ingredientSections.isEmpty ?? false &&
          recipe.steps?.stepSections.isEmpty ?? false
          // TODO: Delete this recipe because it is empty, and propagate all changes to its elders
          return .none
          
        case .none:
          return .none
        }
        
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
private extension AppReducer {
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
  
  func folderNavigateToFolder(state: inout State, pathID: StackElementID, id: FolderGridItemReducer.State.ID) -> Effect<Action> {
    guard let element = state.path[id: pathID],
          case let .folder(folderState) = element,
          let folder = folderState.folders.folders[id: id]
    else { return .none }
    return navigateToFolder(state: &state, folder: folder)
  }
  
  func folderNavigateToRecipe(state: inout State, pathID: StackElementID, id: RecipeGridItemReducer.State.ID) -> Effect<Action> {
    guard let element = state.path[id: pathID],
          case let .folder(folderState) = element,
          let recipe = folderState.recipes.recipes[id: id]
    else { return .none }
    return navigateToRecipe(state: &state, recipe: .init(recipe: recipe.recipe))
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

