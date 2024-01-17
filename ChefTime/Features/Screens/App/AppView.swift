import SwiftUI
import ComposableArchitecture

// I think the problem is that the rootfoldersview is rendered at init anyway, despite the if/else...
// so we have to somehow block that view from doing anything...

// TODO: Make sure to refresh when nav back to screen.
struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.stack, action: AppReducer.Action.stack)) {
        RootFoldersView(store: store.scope(state: \.rootFolders, action: AppReducer.Action.rootFolders))
      } destination: { state in
        switch state {
        case .folder:
          CaseLet(
            /AppReducer.StackReducer.State.folder,
             action: AppReducer.StackReducer.Action.folder,
             then: FolderView.init(store:)
          )
        case .recipe:
          CaseLet(
            /AppReducer.StackReducer.State.recipe,
             action: AppReducer.StackReducer.Action.recipe,
             then: RecipeView.init(store:)
          )
        }
      }
      .task {
        await viewStore.send(.task).finish()
      }
    }
  }
}

#Preview {
  AppView(store: .init(
    initialState: .init(),
    reducer: AppReducer.init
  ))
}
