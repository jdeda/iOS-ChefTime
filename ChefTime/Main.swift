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
//            AppView()
          NavigationStack {
            ScrollView {
              IngredientsListView(store: .init(
                initialState: .init(viewState: .init(ingredients: Recipe.mock.ingredients)),
                reducer: IngredientsListReducer.init,
                withDependencies: { _ in
                  // TODO:
                }
              ))
            }
            .padding()
          }
        }
    }
}
