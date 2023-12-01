import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let store = StoreOf<AppReducer>(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  )
  
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        Text("XCTIsTesting")
      }
      else {
        AppView(store: store)
          .onAppear {
            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
          }
      }
    }
  }
}
