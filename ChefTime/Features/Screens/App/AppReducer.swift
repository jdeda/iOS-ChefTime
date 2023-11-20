import SwiftUI
import ComposableArchitecture

// MARK: - Reducer
struct AppReducer: Reducer {
  struct State: Equatable {
    var stack = StackState<StackReducer.State>()
    var folders = FoldersReducer.State()
  }
  
  enum Action: Equatable {
    case stack(StackAction<StackReducer.State, StackReducer.Action>)
    case folders(FoldersReducer.Action)
  }
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    Scope(state: \.folders, action: /Action.folders) {
      FoldersReducer()
    }
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
      case .stack:
        return .none
        
        // All possible folder navigation.
      case let .stack(.element(id: id, action: .folder(.delegate(delegateAction)))):
        // TODO: Remove force unwraps before production.
        let folder = CasePath(StackReducer.State.folder).extract(from: state.stack[id: id])!
        if let newStackElement: StackReducer.State = {
          switch delegateAction {
          case let .addNewFolderDidComplete(childID):
             .folder(.init(folderID: folder.folder.folders[id: childID]!.id))
          case let .addNewRecipeDidComplete(childID):
             .recipe(.init(recipeID: folder.folder.recipes[id: childID]!.id))
          case let .folderTapped(childID):
             .folder(.init(folderID: folder.folder.folders[id: childID]!.id))
          case let .recipeTapped(childID):
             .recipe(.init(recipeID: folder.folder.recipes[id: childID]!.id))
          case .folderUpdated:
             nil
          }
        }() {
          state.stack.append(newStackElement)
        }
        return .none
        
      case .folders:
        return .none
      }
    }
    .forEach(\.stack, action: /Action.stack) {
      StackReducer()
    }
  }
}

extension AppReducer {
  struct StackReducer: Reducer {
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
