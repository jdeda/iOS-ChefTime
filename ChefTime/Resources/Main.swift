import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
//      if _XCTIsTesting {
        RecipeView(store: .init(
          initialState: RecipeReducer.State(
            recipe: .longMock
          ),
          reducer: RecipeReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
//      }
    }
  }
}
