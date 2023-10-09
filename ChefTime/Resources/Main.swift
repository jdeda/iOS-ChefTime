import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let recipeUUIIDString = "4E2B0674-B7E6-4585-8636-6F552E42A570"

  var body: some Scene {
    WindowGroup {
      //            if _XCTIsTesting {
      NavigationStack {
        RecipeView(store: .init(
          initialState: .init(
//            recipe: Recipe.longMock
            recipeID: .init(rawValue: .init(uuidString: recipeUUIIDString)!)
          ),
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
