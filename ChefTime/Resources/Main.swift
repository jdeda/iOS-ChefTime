import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let store: StoreOf<AppReducer>
  let viewStore: ViewStoreOf<AppReducer>

  init() {
    self.store = .init(
      initialState: AppReducer.State(),
      reducer: AppReducer.init
    )
    self.viewStore = .init(self.store, observe: { $0 })
  }
  
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        Text("XCTIsTesting")
      }
      else {
        //        LoadDBView()
        //                  AppView(store: .init(
        //                    initialState: AppReducer.State(),
        //                    reducer: AppReducer.init
        //                  ))
        AppView(store: store)
        
        //        NavigationStack {
        //          RecipeView(store: .init(
        //            initialState: .init(recipeID: .init()),
        //            reducer: RecipeReducer.init,
        //            withDependencies: {
        //              $0.database = .preview
        //            }
        //          ))
        //        }
          .onAppear {
            viewStore.send(.appDidStart)
            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
          }
      }
    }
  }
}
