import SwiftUI
import ComposableArchitecture

  // TODO: Make sure to refresh when nav back to screen.
// TODO: Somethinghn wrong with images

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        if viewStore.loadStatus == .isLoading {
          ProgressView()
        } else {
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
