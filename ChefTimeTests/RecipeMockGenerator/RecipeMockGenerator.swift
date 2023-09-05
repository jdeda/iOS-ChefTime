import XCTest
import ComposableArchitecture
import Tagged
import Dependencies

@testable import ChefTime

@MainActor
final class FeatureTests: XCTestCase {

  let fileName = "recipe_40.json"
  
  func testIO() {
    let io = ReadWriteIO(fileName: fileName)
    io.writeRecipeToDisk(recipe)
    let readRecipe = io.readRecipeFromDisk()
    XCTAssertEqual(readRecipe, recipe)
    print(io.fileURL.absoluteString)
  }
}

// MARK: - ReadWriteIO
struct ReadWriteIO {
  let fileName: String
  
  var fileURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first!
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


// MARK: - Recipe
let recipe = Recipe(
  id: .init(),
  name: "Biscuits and Gravy",
  imageData: [
    .init(
      id: .init(),
      data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_00", withExtension: "jpeg")!))!
    )!,
    .init(
      id: .init(),
      data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_08", withExtension: "jpeg")!))!
    )!,
  ],
  aboutSections: [
    .init(id: .init(), name: "About", description: "Homemade biscuits and gravy completely from scratch. If you have never had a proper homemade biscuit, you are very, very much missing out. The taste and texture is light-years ahead of that wretched instant canned biscuits. These will melt your face with how good they are. You will never be the same after these. And the gravy? Well, there is a reason this meal is revered. Follow the biscuits to an absolute tee or you probably won't get the same result. Zero substitutions for anything. No cream, no milk, only buttermilk. No self rising flour. Butter must be frozen. Rising agents and salt precisely measured. Knead carefully. Its not hard just follow the steps. Go ahead and give it go!")
  ],
  ingredientSections: [
    .init(id: .init(), name: "Biscuits", ingredients: [
      .init(id: .init(), name: "All Purpose Flour", amount: 15, measure: "oz"),
      .init(id: .init(), name: "Kosher Salt", amount: 1.5, measure: "tsps"),
      .init(id: .init(), name: "Cane Sugar", amount: 2, measure: "tbsps"),
      .init(id: .init(), name: "Baking Powder", amount: 4, measure: "tsps"),
      .init(id: .init(), name: "Baking Soda", amount: 0.5, measure: "tsp"),
      .init(id: .init(), name: "Frozen Unsalted Cultured Butter", amount: 8, measure: "oz"),
      .init(id: .init(), name: "High-Fat Buttermilk", amount: 1.25, measure: "cups")
    ]),
    .init(id: .init(), name: "Gravy", ingredients: [
      .init(id: .init(), name: "Country Sausage", amount: 1, measure: "lb"),
      .init(id: .init(), name: "All Purpose Flour", amount: 2, measure: "tbsp"),
      .init(id: .init(), name: "Kosher Salt", amount: 1, measure: "to taste"),
      .init(id: .init(), name: "Fresh Ground Black Pepper", amount: 1.5, measure: "to taste"),
      .init(id: .init(), name: "High-Fat Whole-Milk", amount: 1, measure: "to texture")
    ]),
  ],
  stepSections: [
    .init(id: .init(), name: "Biscuits", steps: [
      .init(id: .init(), description: "Combine all the dry ingredients into a bowl and thoroughly mix. Grate the frozen butter and mix into the flour. Then add the buttermilk and mix until you get a shaggy dough. You must have frozen butter or this will not turn out proper. You also want very cold buttermilk and don't let the mixture heat up too much or the butter will melt. Do not overknead, just do so until everything is just barely combined and the dough looks shaggy. As soon as that is done, through in the freezer for ten minutes for the butter to stay frozen.", imageData: [
        .init(
          id: .init(),
          data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_04", withExtension: "jpeg")!))!
        )!,
      ]),
      .init(id: .init(), description: "Remove from fridge, roll flat, and repeat a fold and flip method three times. Then cut into cubes lay on a tray, brush tops with butter and bake in a preheated 400F oven for 15 minutes or until they are golden brown. When finished baking brush with more butter, this is cructial so it doesn't dry out.", imageData: [
        .init(
          id: .init(),
          data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_05", withExtension: "jpeg")!))!
        )!,
      ]),
    ]),
    .init(id: .init(), name: "Gravy", steps: [
      .init(id: .init(), description: "Start browning the sausage in a cold pan over medium heat. Break the meat into small chunks and as soon as it starts to get fairly crispy, add the flour and cook for 2 minutes. Then slowly add the milk and whisk constantly so you don't get lumps. This is critical. Season with salt and pepper, be very generous on the pepper, its very critical to this gravy!", imageData: [
        .init(
          id: .init(),
          data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_07", withExtension: "jpeg")!))!
        )!,
        .init(
          id: .init(),
          data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_01", withExtension: "jpeg")!))!
        )!,
      ])
    ]),
    .init(id: .init(), name: "Serve", steps: [
      .init(id: .init(), description: "Slice your biscuits in half, smother them in gravy, and enjoy this revered meal!", imageData: [
        .init(
          id: .init(),
          data: (try? Data(contentsOf: Bundle.main.url(forResource: "img_08", withExtension: "jpeg")!))!
        )!,
      ])
    ]),
  ]
)
