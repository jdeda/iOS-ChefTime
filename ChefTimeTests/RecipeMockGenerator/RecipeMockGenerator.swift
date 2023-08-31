import XCTest
import ComposableArchitecture
import Tagged
import Dependencies

@testable import ChefTime

@MainActor
final class FeatureTests: XCTestCase {
  
  let fileName = "recipe_02.json"
  
  func testIO() {
    let io = ReadWriteIO(fileName: fileName)
    io.writeRecipeToDisk(recipe)
    let readRecipe = io.readRecipeFromDisk()
    XCTAssertEqual(readRecipe, recipe)
  }
}

// MARK: - ReadWriteIO
struct ReadWriteIO {
  let fileName: String
  
  var fileURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first!
//      .appendingPathComponent("ChefTimeTests")
//      .appendingPathComponent("RecipeMockGenerator")
      .appendingPathComponent(fileName)
  }
  
  func writeRecipeToDisk(_ recipe: Recipe) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(recipe)
    try! data.write(to: fileURL, options: .atomic)
  }
  
  func readRecipeFromDisk() -> Recipe {
    let data = try! Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let recipe = try! decoder.decode(Recipe.self, from: data)
    return recipe
  }
}

//Bundle(for: "ChefTimeTests").url(forResource: "img_00", withExtension: "jpeg")!
 
// MARK: - Recipe
let recipe = Recipe(
  id: .init(),
  name: "Cherry Tomato & Onion Quiches",
  imageData: [
//    .init(
//      id: .init(),
//      data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_00", withExtension: "jpeg")!))!
//    )!,
  ],
  aboutSections: [
    .init(id: .init(), name: "About", description: "Tonight’s meal takes advantage of some of summer’s brightest, most flavorful produce. At the base of our quiches are cherry tomatoes (yours may be red or yellow) and red onion—briefly sautéed to soften them and bring out their sweetness. We’re adding the vegetables to a mix of eggs and creamy ricotta, then baking it all inside buttery pastry. A side of sweet sautéed corn and tender summer squash completes the dish with another seasonal lift.")
  ],
  ingredientSections: [
    .init(id: .init(), name: "Ingredients", ingredients: [
      .init(id: .init(), name: "eggs", amount: 2, measure: "whole, large", isComplete: false),
      .init(id: .init(), name: "pie crusts", amount: 2, measure: "sheets, large", isComplete: false),
      .init(id: .init(), name: "part-skin ricotta cheese", amount: 0.5, measure: "cup", isComplete: false),
      .init(id: .init(), name: "garlic", amount: 2, measure: "whole, large", isComplete: false),
      .init(id: .init(), name: "ear of corn", amount: 1, measure: "whole", isComplete: false),
      .init(id: .init(), name: "summer squash", amount: 1, measure: "whole", isComplete: false),
      .init(id: .init(), name: "chives", amount: 1, measure: "bundle", isComplete: false),
      .init(id: .init(), name: "white wine vinegar", amount: 1, measure: "tbsp", isComplete: false),
      .init(id: .init(), name: "red onion", amount: 1, measure: "medium", isComplete: false),
      .init(id: .init(), name: "cherry tomatoes", amount: 6, measure: "oz", isComplete: false),
    ])
  ],
  stepSections: [
    .init(id: .init(), name: "Prepare the ingredients", steps: [
      .init(
        id: .init(),
        description: "Preheat the oven to 425°F. Wash and dry the fresh produce. Peel and large dice the onion. Peel and roughly chop the garlic. Halve the tomatoes; place in a bowl and season with salt and pepper. Medium dice the squash. Remove and discard the corn husks and silks. Cut the corn kernels off the cob; discard the cob. Thinly slice the chives. ",
        imageData: [
//          .init(
//            id: .init(),
//            data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_01", withExtension: "jpeg")!))!
//          )!,
        ])
    ]),
    .init(id: .init(), name: "Cook the onion & tomatoes", steps: [
      .init(
        id: .init(),
        description: "In a medium pan (nonstick, if you have one), heat 1 teaspoon of olive oil on medium-high until hot. Add the onion and garlic; season with salt and pepper. Cook, stirring occasionally, 3 to 4 minutes, or until softened and fragrant. Add the seasoned tomatoes and cook, stirring frequently, 3 to 4 minutes, or until softened. Turn off the heat; season with salt and pepper to taste.",
        imageData: [
//          .init(
//            id: .init(),
//            data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_02", withExtension: "jpeg")!))!
//          )!,
        ])
    ]),
    .init(
      id: .init(), name: "Make the filling", steps: [
        .init(
          id: .init(),
          description: "Crack the eggs into a large bowl and beat until smooth. Whisk in the ricotta cheese and 2 tablespoons of water. Add the cooked onion and tomatoes; gently stir to combine. Season with salt and pepper.",
          imageData: [
//            .init(
//              id: .init(),
//              data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_03", withExtension: "jpeg")!))!
//            )!,
          ])
      ]),
    .init(id: .init(), name: "Assemble & bake the quiches", steps: [
      .init(
        id: .init(),
        description: "Place the pie crusts on a sheet pan, leaving them in their tins. Evenly divide the filling between the pie crusts. Bake 18 to 20 minutes, or until the crusts have browned and the filling is set and cooked through. Remove from the oven and let stand for at least 5 minutes.",
        imageData: [
//          .init(
//            id: .init(),
//            data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_04", withExtension: "jpeg")!))!
//          )!,
        ])
    ]),
    .init(id: .init(), name: "Cook the squash & corn", steps: [
      .init(
        id: .init(),
        description: "Once the quiches have baked for about 10 minutes, wipe out the pan used to cook the onion and tomatoes. In the same pan, heat 2 teaspoons of olive oil on medium-high until hot. Add the squash in a single layer. Cook, without stirring, 3 to 5 minutes, or until lightly browned. Add the corn; season with salt and pepper. Cook, stirring occasionally, 4 to 6 minutes, or until softened. Turn off the heat and stir in the vinegar. Season with salt and pepper to taste. Transfer to a serving dish.",
        imageData: [
//          .init(
//            id: .init(),
//            data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_05", withExtension: "jpeg")!))!
//          )!,
        ])
    ]),
    .init(id: .init(), name: "Plate your dish", steps: [
      .init(
        id: .init(),
        description: "Transfer the baked quiches to a serving dish. Garnish the cooked squash and corn with the chives. Enjoy!",
        imageData: [
//          .init(
//            id: .init(),
//            data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_06", withExtension: "jpeg")!))!
//          )!,
        ])
    ]),
  ]
)
