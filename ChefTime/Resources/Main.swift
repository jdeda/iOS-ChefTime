import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "456DBE9B-E519-4A79-8DE6-7078C47E3A7D"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        //        RecipeView(store: .init(
        ////          initialState: .init(recipeID: .init(uuidString: uuidString)!),
        //          initialState: .init(recipe: .longMock),
        //          reducer: RecipeReducer.init
        //        ))
//        FolderView(store: .init(
//          initialState: .init(
//            folderID: .init(uuidString: uuidString)!
////            folder: .longMock
//          ),
//          reducer: FolderReducer.init
//        ))
        LoadView()
      }
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}
