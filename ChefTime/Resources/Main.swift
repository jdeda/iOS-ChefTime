import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "C2968483-6FA1-4CFF-9C7B-B3DB43DDDF31"
  
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
//            folderID: .init(uuidString: uuidString)!,
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
