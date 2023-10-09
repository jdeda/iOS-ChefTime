import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let recipeUUIIDString = "C89AA66E-87C7-48DB-B26B-A46125750DBE"

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
