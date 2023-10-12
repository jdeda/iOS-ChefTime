import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "B9FBD9C4-FC5F-4EC3-9FE3-D81324F103D9"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        FolderView(store: .init(
          initialState: .init(
            folderID: .init(uuidString: uuidString)!
//            folder: Folder.longMock
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
