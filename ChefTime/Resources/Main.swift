import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
      //            if _XCTIsTesting {
      AppView()
        .onAppear {
          UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
        }
      //            }
    }
  }
}

/// 1. Settings
/// 2. Folders
///   - Folders
///   - Recipes
