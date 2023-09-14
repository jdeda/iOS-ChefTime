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
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .path(.element(id: id, action: .folder(action))):
        return .none
        
      case let .path(.element(id: id, action: .recipe(action))):
        return .none
        
      case .folders:
        return .none
        
      case .path:
        return .none
      }
    }
  }
}

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

