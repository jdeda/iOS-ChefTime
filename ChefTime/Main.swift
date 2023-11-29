import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay

@main
struct ChefTimeApp: App {
  let store: StoreOf<AppReducer>
  let viewStore: ViewStoreOf<AppReducer>

  init() {
    self.store = .init(
      initialState: AppReducer.State(),
      reducer: AppReducer.init
    )
    self.viewStore = .init(self.store, observe: { $0 })

#if DEBUG
#if targetEnvironment(simulator)
      // in debug, on simulator, the db does not exist
      // create it, make a copy to my git
      let exist = (try? MockDataGenerator.gitStoreFile.checkResourceIsReachable()) ?? false
      if exist {
          // TODO: if the app file is there do not replace it ...
          try? FileManager.default.removeItem(at: MockDataGenerator.storeFile)
          try? FileManager.default.copyItem(at: MockDataGenerator.gitStoreFile, to: MockDataGenerator.storeFile)
      }
#else
      // in debug, on device
      // we just need to copy the embedded db, into the sandbox
      try? FileManager.default.removeItem(at: MockDataGenerator.storeFile)
      try? FileManager.default.copyItem(at: MockDataGenerator.embeddedFile, to: MockDataGenerator.storeFile)
#endif
#endif
  }
  
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        Text("XCTIsTesting")
      }
      else {
        //        LoadDBView()
        //                  AppView(store: .init(
        //                    initialState: AppReducer.State(),
        //                    reducer: AppReducer.init
        //                  ))
        AppView(store: store)
        
        //        NavigationStack {
        //          RecipeView(store: .init(
        //            initialState: .init(recipeID: .init()),
        //            reducer: RecipeReducer.init,
        //            withDependencies: {
        //              $0.database = .preview
        //            }
        //          ))
        //        }
          .onAppear {
            viewStore.send(.appDidStart)
            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
          }
      }
    }
  }
}
