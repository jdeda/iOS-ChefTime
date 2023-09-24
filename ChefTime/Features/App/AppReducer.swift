import SwiftUI
import ComposableArchitecture

/// Let's see how we can refactor our code and add features to handle persistence and synchronization of destinations in the stack.
/// First, we want to synchronize any changes that occur in the destination to be interecepted so that we may update our real state.

// MARK: - Reducer
/// This feature does one thing and one thing only: control all navigation for the folders, folder, recipe, and search.
struct AppReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var user: User? = nil
    var folders = FoldersReducer.State()
  }
  
  enum Action: Equatable {
    case task
    case fetchUserSuccess(User)
    case saveUser
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case folders(FoldersReducer.Action)
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.database) var db
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(state: \.folders, action: /Action.folders) {
      FoldersReducer()
    }
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
        
      case .task:
        guard state.user != nil else { return .none }
        return .run { send in
          guard let user = await db.fetchUser()
          else { return }
          await send(.fetchUserSuccess(user), animation: .default)
        }
        
      case let .fetchUserSuccess(user):
        state.user = user
        let systemSection = FolderSectionReducer.State(
          title: "Folders",
          folders: .init(uniqueElements: user.systemFolders.map { .init(id: .init(rawValue: uuid()), folder: $0) })
        )
        let userSection = FolderSectionReducer.State(
          title: "Folders",
          folders: .init(uniqueElements: user.userFolders.map { .init(id: .init(rawValue: uuid()), folder: $0) })
        )
        state.folders = .init(systemFoldersSection: systemSection, userFoldersSection: userSection)
        return .none
        
      case .saveUser:
        guard let user = state.user
        else { return .none }
        return .run { _ in
          await db.updateUser(user)
        }
        
        
        // Recipe triggers an update.
      case let .path(.element(id: pathID, action: .recipe(.delegate(.recipeUpdated(recipeFeatureState))))):
//        return .run {
//          await db.updateRecipe(recipe)
//        }
        return .none
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folder triggers an update.
      case let .path(.element(id: pathID, action: .folder(.delegate(.folderUpdated(folderFeatureState))))):
//        return .run {
//          await db.updateFolder(folder)
//        }
        // TODO: Propagate all changes from this path element to all its elders
        return .none
        
        // Folder taps into a folder.
      case let .path(.element(id: pathID, action: .folder(.folders(.delegate(.folderTapped(id)))))):
        return folderNavigateToFolder(state: &state, pathID: pathID, id: id)
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folder taps into a recipe.
      case let .path(.element(id: pathID, action: .folder(.recipes(.delegate(.recipeTapped(id)))))):
        return folderNavigateToRecipe(state: &state, pathID: pathID, id: id)
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folder creates a new folder.
      case let .path(.element(id: pathID, action: .folder(.delegate(.addNewFolderButtonTappedDidComplete(id))))):
        return folderNavigateToFolder(state: &state, pathID: pathID, id: id)
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folder creates a new recipe.
      case let .path(.element(id: pathID, action: .folder(.delegate(.addNewRecipeButtonTappedDidComplete(id))))):
        return folderNavigateToRecipe(state: &state, pathID: pathID, id: id)
        // TODO: Propagate all changes from this path element to all its elders
        
        
        // Folders.UserFolders taps into a folder.
      case let .folders(.userFoldersSection(.delegate(.folderTapped(id)))):
        guard let folder = state.folders.userFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folders.SystemFolders taps into a folder
      case let .folders(.systemFoldersSection(.delegate(.folderTapped(id)))):
        guard let folder = state.folders.systemFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folders creates a new folder (can only create a user folder)
      case let .folders(.delegate(.addNewFolderButtonTappedDidComplete(id))):
        guard let folder = state.folders.userFoldersSection.folders[id: id]
        else { return .none }
        return navigateToFolder(state: &state, folder: folder)
        // TODO: Propagate all changes from this path element to all its elders
        
        // Folders creates a new recipe (will only add one to the standard folder)
      case let .folders(.delegate(.addNewRecipeButtonTappedDidComplete(id))):
        guard let recipe = state.folders.systemFoldersSection.folders[1].folder.recipes[id: id]
        else { return .none }
        return navigateToRecipe(state: &state, recipe: .init(recipe: recipe))
        // TODO: Propagate all changes from this path element to all its elders
        

      case let .path(.popFrom(id: id)):
        switch state.path[id: id] {
        case let .folder(folder):
//          let isEmpty = folder.folder.folders.folders.isEmpty && folder.folder.recipes.recipes.isEmpty
//          // TODO: Delete this folder because it is empty, and propagate all changes to its elders
          return .none
          
        case let .recipe(recipe):
//          let isEmpty = recipe.photos.photos.isEmpty &&
//          recipe.about?.aboutSections.isEmpty ?? false  &&
//          recipe.ingredients?.ingredientSections.isEmpty ?? false &&
//          recipe.steps?.stepSections.isEmpty ?? false
//          // TODO: Delete this recipe because it is empty, and propagate all changes to its elders
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
      folderModel: .init(
        name: folder.folder.name,
        folders: .init(title: "Folders", folders: .init(uniqueElements: folder.folder.folders.map {
          .init(id: .init(rawValue: uuid()), folder: $0)
        })),
        recipes: .init(title: "Recipes", recipes: .init(uniqueElements: folder.folder.recipes.map {
          .init(id: .init(rawValue: uuid()), recipe: $0)
        }))
      )
    )))
    return .none
  }
  
  func navigateToRecipe(state: inout State, recipe: RecipeReducer.State) -> Effect<Action> {
    state.path.append(.recipe(recipe))
    return .none
  }
  
  func folderNavigateToFolder(
    state: inout State,
    pathID: StackElementID,
    id: FolderGridItemReducer.State.ID
  ) -> Effect<Action> {
    guard let element = state.path[id: pathID],
          case let .folder(folderState) = element,
          let folder = folderState.folderModel.folders.folders[id: id]
    else { return .none }
    
    return navigateToFolder(state: &state, folder: folder)
  }
  
  func folderNavigateToRecipe(
    state: inout State,
    pathID: StackElementID,
    id: RecipeGridItemReducer.State.ID
  ) -> Effect<Action> {
    guard let element = state.path[id: pathID],
          case let .folder(folderState) = element,
          let recipe = folderState.folderModel.recipes.recipes[id: id]
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
