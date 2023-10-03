import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
      //            if _XCTIsTesting {
      NavigationStack {
        RecipeView(store: .init(
          initialState: .init(recipe: Recipe.longMock),
          reducer: RecipeReducer.init
        ))
      }

      //      AppView(store: .init(
//        initialState: .init(),
//        reducer: AppReducer.init
//      ))
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
