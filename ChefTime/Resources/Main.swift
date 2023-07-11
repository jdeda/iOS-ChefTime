import SwiftUI

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
      if NSClassFromString("XCTestCase") == nil {        
        RecipeView(store: .init(
          initialState: RecipeReducer.State(
            recipe: .longMock
          ),
          reducer: RecipeReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
    }
  }
}
