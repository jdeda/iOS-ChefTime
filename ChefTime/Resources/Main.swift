//import SwiftUI
//
//@main
//struct ChefTimeApp: App {
//  var body: some Scene {
//    WindowGroup {
//      NavigationStack {
//        RecipeView(store: .init(
//          initialState: RecipeReducer.State(
//            recipe: .mock,
//            ingredientsList: .init(recipe: .mock, isExpanded: true),
//            stepsList: .init(recipe: .mock, isExpanded: true),
//            about: .init(isExpanded: true, description: Recipe.mock.about)
//          ),
//          reducer: RecipeReducer.init,
//          withDependencies: { _ in
//            // TODO:
//          }
//        ))
//        .scrollContentBackground(.hidden)
//        .background {
//          Image(systemName: "recipe_05")
//            .resizable()
//            .scaledToFill()
//            .blur(radius: 10)
//            .ignoresSafeArea()
//        }
//      }
//    }
//  }
//}

import SwiftUI

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
      RecipeView(store: .init(
        initialState: RecipeReducer.State(
          recipe: .longMock
        ),
        reducer: RecipeReducer.init,
        withDependencies: { _ in
          // TODO:
        }
      ))
//      FeatureView(store: .init(initialState: .init(), reducer: FeatureReducer.init()))
    }
  }
}
