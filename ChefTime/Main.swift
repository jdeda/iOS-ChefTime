import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay
import Log4swift

@main
struct ChefTimeApp: App {
  let store = StoreOf<AppReducer>(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  )
  
    init() {
        Log4swift.configure(appName: "ChefTime")
        Log4swift[Self.self].info("")
    }

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
