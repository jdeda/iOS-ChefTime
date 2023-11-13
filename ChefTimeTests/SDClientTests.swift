import XCTest
import ComposableArchitecture
import Dependencies
import SwiftData

@testable import ChefTime

@MainActor
final class SDClientTests: XCTestCase {
  
  func testInit() async {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders(FetchDescriptor<SDFolder>())
    let recipes = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(folders.isEmpty)
    XCTAssertTrue(recipes.isEmpty)
  }
  
  func testCreateRecipe() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let recipes = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(recipes.isEmpty)
    
    // Let's add an empty butter recipe.
    let recipe = Recipe(id: .init(), name: "Butter")
    try await sdc.createRecipe(recipe)
    let newRecipes = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(newRecipes.count == 1)
    XCTAssertTrue(newRecipes.first == recipe)
    
    // Let's add a chocolate gravy recipe.
    let recipe2 = testRecipe
    try await sdc.createRecipe(recipe2)
    let newRecipes2 = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(newRecipes2.count == 2)
    XCTAssertEqual(recipe, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe.id })))
    dump(diff(recipe2, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe2.id }))))
    XCTAssertEqual(recipe2, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe2.id })))
  }
}

let testRecipe = Recipe(
  id: .init(),
  name: "Chocolate Gravy",
  imageData: [],
  aboutSections: [.init(id: .init(), name: "About", description: "My dear mother's favorite late night snack. Perfect over white bread or biscuits.")],
  ingredientSections: [.init(id: .init(), name: "Ingredients", ingredients: [
    .init(id: .init(), name: "Butter", amount: 1/4, measure: "cup"),
    .init(id: .init(), name: "Flour", amount: 0.25, measure: "cup"),
    .init(id: .init(), name: "Cocoa Powder", amount: 1/4, measure: "cup"),
    .init(id: .init(), name: "Milk", amount: 2, measure: "cups"),
    .init(id: .init(), name: "Sugar", amount: 1, measure: "cup"),
    .init(id: .init(), name: "Vanilla Extract", amount: 1, measure: "tbsp"),
  ])],
  stepSections: [.init(id: .init(), name: "Cooking", steps: [
    .init(id: .init(), description: "Make the (literal) chocolate roux. Add the butter, flour, and cocoa powder to a pot, turn heat to medium heat and stir for 5 minutes"),
    .init(id: .init(), description: "Once the roux is cooked, add the milk slowly, constantly stirring to prevent lumps. If you get lumps just stick it into the blender (but don't melt the blender!). Finish by adding the sugar and vanilla extract and simmer five minutes."),
    .init(id: .init(), description: "Serve over white bread or biscuits! Enjoy!")
  ])]
)
