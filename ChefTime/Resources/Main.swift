import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let folderUUIDString = "3DF50638-9B9A-48AB-87FF-9D7B943DF494"
  let recipeUUIDString = "3DF50638-9B9A-48AB-87FF-9D7B943DF494"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
//        LoadDBView()
        FoldersView(store: .init(
          initialState: .init(),
          reducer: FoldersReducer.init,
          withDependencies: {
            $0.database = .preview
          }
        ))
//        RecipeView(store: .init(
//          initialState: .init(
//            recipeID: .init(uuidString: recipeUUIDString)!
//          ),
//          reducer: RecipeReducer.init
//        ))
//        FolderView(store: .init(
//          initialState: .init(
//            folderID: .init(uuidString: folderUUIDString)!
//          ),
//          reducer: FolderReducer.init
//        ))
      }
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}
