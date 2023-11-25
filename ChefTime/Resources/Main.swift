import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
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
        AppView(store: .init(
          initialState: AppReducer.State(),
          reducer: AppReducer.init,
          withDependencies: {
            $0.database = .preview
          }
        ))
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
          UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
        }
      }
    }
  }
}
