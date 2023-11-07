import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
//  let folderUUIDString = "0301FBE4-9608-4847-A719-40046006814C"
//  let recipeUUIDString = "B895299B-2A60-43A8-96D4-DF1DF778144D"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
//        LoadDBView()
//        FoldersView(store: .init(
//          initialState: FoldersReducer.State(),
//          reducer: FoldersReducer.init
//        ))
//        FolderView(store: .init(
//          initialState: .init(folderID: .init(uuidString: folderUUIDString)!),
//          reducer: FolderReducer.init
//        ))
//        RecipeView(store: .init(
//          initialState: .init(recipeID: .init(uuidString: recipeUUIDString)!),
//          reducer: RecipeReducer.init
//        ))
      }
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}
