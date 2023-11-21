import SwiftUI
import ComposableArchitecture

// MARK: - View
struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.stack, action: AppReducer.Action.stack)) {
        FoldersView(store: store.scope(state: \.folders, action: AppReducer.Action.folders))
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
}


// MARK: - Preview
#Preview {
  AppView(store: .init(
    initialState: .init(),
    reducer: AppReducer.init
  ))
}
