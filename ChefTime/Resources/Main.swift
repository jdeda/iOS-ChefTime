import SwiftUI
import XCTestDynamicOverlay

// TODO: Ordering isnt working possibly.
@main
struct ChefTimeApp: App {
  //  let folderUUIDString = "0301FBE4-9608-4847-A719-40046006814C"
  let recipeUUIDString = "9F50FD47-9744-4D49-9D09-5EE8DA38EE89"
  
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        Text("XCTIsTesting")
      }
      else {
        NavigationStack {
          AppView(store: .init(
            initialState: AppReducer.State(),
            reducer: AppReducer.init
          ))
        }
        .onAppear {
          UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
        }
      }
    }
  }
}
