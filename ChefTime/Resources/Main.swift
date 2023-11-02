import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "7849C3FC-A5FE-4F4E-813A-D46411A50185"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
//        RecipeView(store: .init(
////          initialState: .init(recipeID: .init(uuidString: uuidString)!),
//          initialState: .init(recipe: .longMock),
//          reducer: RecipeReducer.init
//        ))
        FolderView(store: .init(
          initialState: .init(
//            folderID: .init(uuidString: uuidString)!
            folder: .longMock
          ),
          reducer: FolderReducer.init
        ))
      }
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}
