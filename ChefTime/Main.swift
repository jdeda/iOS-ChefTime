import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay
import Log4swift

@main
struct ChefTimeApp: App {
    @State var isLoading = true

    let store = StoreOf<AppReducer>(
        initialState: AppReducer.State(),
        reducer: AppReducer.init
    )

    init() {
        Log4swift.configure(appName: "ChefTime")
        Log4swift[Self.self].info("")
    }

    var body: some Scene {
        WindowGroup {
            if _XCTIsTesting {
                Text("XCTIsTesting")
            }
            else {
                // Quick turn around debug
                NavigationStack {
                    if self.isLoading {
                        Color.yellow
                            .task {
                                @Dependency(\.database) var database
                                await database.initializeDatabase()
                                self.isLoading = false
                            }
                    } else {
                        RecipeView(store: .init(
                            initialState: RecipeReducer.State(
                                recipeID: .init(rawValue: .init(uuidString: "C1F95C7B-CE33-46EB-B0EA-321F31F03672")!)

                            ),
                            reducer: RecipeReducer.init
                        ))
                    }
                }
                //          AppView(store: store)
                //              .onAppear {
                //                  UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
                //              }
            }
        }
    }
}
