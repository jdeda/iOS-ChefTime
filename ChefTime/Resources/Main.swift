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
//      NavigationStack {
//        StepView(store: .init(
//          initialState: .init(
//            id: .init(),
//            stepNumber: 1,
//            step: Recipe.longMock.steps.first!.steps.first!
//          ),
//          reducer: StepReducer.init,
//          withDependencies: { _ in
//            // ...
//          }
//        ))
//      }
      NavigationStack {
        IngredientListView(store: .init(
          initialState: .init(
            recipe: Recipe.longMock,
            isExpanded: true,
            childrenIsExpanded: true
          ),
          reducer: IngredientsListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
    }
  }
}
