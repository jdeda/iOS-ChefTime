import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
      //            if _XCTIsTesting {
      AppView()
      //            }
    }
  }
}
