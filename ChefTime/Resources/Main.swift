import SwiftUI
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let uuidString = "A1BA2821-24BA-4C46-8E41-5F98409CCA11"
  
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
