//import SwiftUI
//import ComposableArchitecture
//
//
///// FoldersView
///// FolderView
///// RecipeView
//
///// Let's see how we can refactor our code and add features to handle persistence and synchronization of destinations in the stack.
///// First, we want to synchronize any changes that occur in the destination to be interecepted so that we may update our real state.
//
//// MARK: - View
//struct AppView: View {
//  let store: StoreOf<AppReducer>
//  
//  var body: some View {
//    WithViewStore(store, observe: { $0 }) { viewStore in
//      NavigationStackStore(store.scope(state: \.path, action: AppReducer.Action.path)) {
//        FoldersView(store: store.scope(
//          state: \.folders,
//          action: AppReducer.Action.folders
//        ))
//      } destination: { state in
//        switch state {
//        case .folder:
//          CaseLet(
//            /AppReducer.PathReducer.State.folder,
//             action: AppReducer.PathReducer.Action.folder,
//             then: FolderView.init(store:)
//          )
//        case .recipe:
//          CaseLet(
//            /AppReducer.PathReducer.State.recipe,
//             action: AppReducer.PathReducer.Action.recipe,
//             then: RecipeView.init(store:)
//          )
//        }
//      }
//    }
//  }
//}
//
//// MARK: - Preview
//struct AppView_Previews: PreviewProvider {
//  static var previews: some View {
//    AppView(store: .init(
//      initialState: .init(),
//      reducer: AppReducer.init
//    ))
//  }
//}
//
