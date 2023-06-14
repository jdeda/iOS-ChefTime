//
//  ChefTimeApp.swift
//  ChefTime
//
//  Created by Jesse Deda on 6/5/23.
//

import SwiftUI

@main
struct ChefTimeApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        RecipeView(store: .init(
          initialState: RecipeReducer.State(
            ingredientsList: .init(recipe: .mock, isExpanded: true),
            stepsList: .init(recipe: .mock, isExpanded: true),
            about: .init(isExpanded: true, description: Recipe.mock.about)
          ),
          reducer: RecipeReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .scrollContentBackground(.hidden)
        .background {
          Image(systemName: "recipe_05")
            .resizable()
            .scaledToFill()
            .blur(radius: 10)
            .ignoresSafeArea()
        }
      }
    }
  }
}
