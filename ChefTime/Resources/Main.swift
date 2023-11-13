import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  //  let folderUUIDString = "0301FBE4-9608-4847-A719-40046006814C"
//    let recipeUUIDString = "E4015299-21B1-44CA-8034-6B2B3854FDC9"
  
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        EmptyView()
      }
      else {
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
}
