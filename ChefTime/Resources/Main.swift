import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
//  let folderUUIDString = "3DF50638-9B9A-48AB-87FF-9D7B943DF494"
//  let recipeUUIDString = "3DF50638-9B9A-48AB-87FF-9D7B943DF494"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
//        LoadDBView()
        FoldersView(store: .init(
          initialState: FoldersReducer.State(),
          reducer: FoldersReducer.init
        ))
      }
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}
