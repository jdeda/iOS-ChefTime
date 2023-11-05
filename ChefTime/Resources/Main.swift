import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "3DF50638-9B9A-48AB-87FF-9D7B943DF494"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        FolderView(store: .init(
          initialState: .init(
            folderID: .init(uuidString: uuidString)!
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
