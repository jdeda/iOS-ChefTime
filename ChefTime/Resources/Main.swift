import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "F0B722EB-54D0-42AF-AA90-806413C1F7DE"
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
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
