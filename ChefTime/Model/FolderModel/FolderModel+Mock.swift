import Foundation
import Tagged


// MARK: - Empty Mock.
extension Folder {
  static let emptyMock = Self(id: .init())
}

// MARK: - ShortMock
extension Folder {
  static let shortMock = Self(
    id: .init(),
    name: "My Best Recipes",
    folders: [],
    recipes: .init(uniqueElements: (1...10).map(generateRecipe))
  )
}

// MARK: - LongMock
extension Folder {
  static let longMock = Self(
    id: .init(),
    name: "My Best Recipes",
    folders: .init(uniqueElements: (1...5).map(generateFolder)),
    recipes: .init(uniqueElements: (1...10).map(generateRecipe))
  )
}

// MARK: - LongMock
extension Folder {
  static let giantMock: [Self] = (1...10).map(generateDeepFolder)
}


// MARK: - Mock Helpers
private func generateDeepFolder(_ num: Int) -> Folder {
  .init(
    id: .init(),
    name: "Folder No. \(num)",
    folders: .init(uniqueElements: (1...5).map(generateFolder)),
    recipes: .init(uniqueElements: (1...10).map(generateRecipe))
  )
}

private func generateFolder(_ num: Int) -> Folder {
  .init(
    id: .init(),
    name: "Folder No. \(num)",
    folders: [],
    recipes: .init(uniqueElements: (1...10).map(generateRecipe))
  )
}
                    
private func generateRecipe(_ num: Int) -> Recipe {
  .init(
    id: .init(),
    name: "Double Cheese Burger No. \(num)",
    imageData: [
      .init(
        id: .init(),
        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_00", withExtension: "jpeg")!))!
      )!
    ],
    aboutSections: [
      .init(
        id: .init(),
        name: "Description",
        description: "A proper meat feast, this classical burger is just too good! Homemade buns and ground meat, served with your side of classic toppings, it makes a fantastic Friday night treat or cookout favorite."
      )
    ],
    ingredientSections: [
      .init(
        id: .init(),
        name: "Burger",
        ingredients: [
          .init(id: .init(), name: "Buns", amount: 1, measure: "store pack"),
          .init(id: .init(), name: "Frozen Beef Patties", amount: 1, measure: "lb"),
          .init(id: .init(), name: "Lettuce", amount: 2, measure: "leaves"),
          .init(id: .init(), name: "Tomato", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Onion", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Pickle", amount: 2, measure: "chips"),
          .init(id: .init(), name: "Ketchup", amount: 2, measure: "tbsp"),
          .init(id: .init(), name: "Mustard", amount: 2, measure: "tbsp")
        ]
      ),
    ],
    stepSections: [
      .init(id: .init(), name: "Burger", steps: [
        .init(
          id: .init(),
          description: "Toast the buns"
        ),
        .init(
          id: .init(),
          description: "Fry the burger patties"
        ),
        .init(
          id: .init(),
          description: "Assemble with toppings to your liking"
        ),
      ])
    ]
  )
}
