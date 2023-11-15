import XCTest
import ComposableArchitecture
import Dependencies
import SwiftData

@testable import ChefTime

@MainActor
final class SDClientTests_Folder: XCTestCase {
  
  func testInit() async {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    let recipes = await sdc.retrieveRecipes()
    XCTAssertTrue(folders.isEmpty)
    XCTAssertTrue(recipes.isEmpty)
  }
  
  func testCreateRecipe() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let recipes = await sdc.retrieveRecipes()
    XCTAssertTrue(recipes.isEmpty)
    
    // Let's add an empty butter recipe.
    let recipe = Recipe(id: .init(), name: "Butter")
    try await sdc.createRecipe(recipe)
    let newRecipes = await sdc.retrieveRecipes()
    XCTAssertTrue(newRecipes.count == 1)
    XCTAssertTrue(newRecipes.first == recipe)
    
    // Let's add a complicated recipe:
    let recipe2 = Recipe.longMock
    try await sdc.createRecipe(recipe2)
    let newRecipes2 = await sdc.retrieveRecipes()
    XCTAssertTrue(newRecipes2.count == 2)
    XCTAssertEqual(recipe, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe.id })))
    dump(diff(recipe2, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe2.id }))))
    XCTAssertEqual(recipe2, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe2.id })))
  }
  
  func testCreateDupeRecipe() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let recipes = await sdc.retrieveRecipes()
    XCTAssertTrue(recipes.isEmpty)
    
    // Let's add an empty butter recipe.
    let recipe = Recipe(id: .init(), name: "Butter")
    try await sdc.createRecipe(recipe)
    let newRecipes = await sdc.retrieveRecipes()
    XCTAssertTrue(newRecipes.count == 1)
    XCTAssertTrue(newRecipes.first == recipe)
    
    // Lets try to add it again (dupe)
    do {
      try await sdc.createRecipe(recipe)
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.duplicate)
    }
    let newRecipes2 = await sdc.retrieveRecipes()
    XCTAssertTrue(newRecipes2.count == 1)
    XCTAssertTrue(newRecipes2.first == recipe)
  }
  
  func testUpdateRecipe() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let recipes = await sdc.retrieveRecipes()
    XCTAssertTrue(recipes.isEmpty)
    
    // Let's add an empty butter recipe.
    let id = Recipe.ID()
    var recipe = Recipe(id: id, name: "Butter")
    try await sdc.createRecipe(recipe)
    let recipeSDC1 = await sdc.retrieveRecipes().first
    XCTAssertEqual(recipe, recipeSDC1)
    
    // Edit the recipe and update it to the DB.
    recipe.name = "Brown Butter"
    recipe.aboutSections.append(.init(id: .init(), name: "About", description: "The only thing better than butter is brown butter!"))
    try await sdc.updateRecipe(recipe)
    let recipeSDC2 = await sdc.retrieveRecipes().first
    XCTAssertEqual(recipe, recipeSDC2)
    
    // Repeat.
    recipe.name = "Holiday Poultry Compound Butter"
    recipe.aboutSections.removeAll()
    recipe.aboutSections.append(.init(id: .init(), name: "About", description: "This butter is perfect for basting poultry with that intense holiday taste and smell!"))
    recipe.ingredientSections.append(.init(id: .init(), name: "Ingredients", ingredients: [
      .init(id: .init(), name: "Butter", amount: 1, measure: "stick"),
      .init(id: .init(), name: "Crushed Garlic", amount: 1, measure: "tbsp"),
      .init(id: .init(), name: "Lemon", amount: 1, measure: "tbsp"),
      .init(id: .init(), name: "Rosemary", amount: 1, measure: "tsp"),
      .init(id: .init(), name: "Thyme", amount: 1, measure: "tsp"),
      .init(id: .init(), name: "Sage", amount: 1, measure: "tsp"),
      .init(id: .init(), name: "Marjoram", amount: 1, measure: "tsp"),
      .init(id: .init(), name: "Black Pepper", amount: 1, measure: "tsp"),
      .init(id: .init(), name: "Nutmeg", amount: 0.25, measure: "tsp"),
      .init(id: .init(), name: "MSG", amount: 1, measure: "tsp"),
    ]))
    try await sdc.updateRecipe(recipe)
    let recipeSDC3 = await sdc.retrieveRecipes().first
    XCTAssertEqual(recipe, recipeSDC3)
    
    // Repeat.
    recipe.stepSections.append(.init(id: .init(), name: "Prepare the Butter, Garlic, and Lemon", steps: [
      .init(id: .init(), description: "Add room temperature butter to a bowl and grate the garlic and lemon zest over it. Do not stir yet."),
    ]))
    recipe.stepSections.append(.init(id: .init(), name: "Prepare the Herbs", steps: [
      .init(id: .init(), description: "Remove all stems from herbs and gently, and precisely cut them into fine pieces without bruising them."),
      .init(id: .init(), description: "Add them to the butter mixture, do not stir yet."),
    ]))
    recipe.stepSections.append(.init(id: .init(), name: "Add the spices", steps: [
      .init(id: .init(), description: "Precisely measure the spices or you will ruin it extremely badly."),
      .init(id: .init(), description: "If you eyeball this you will regret it."),
      .init(id: .init(), description: "Add them to the butter mixture, do not stir yet."),
    ]))
    recipe.stepSections.append(.init(id: .init(), name: "Gently Mix and Refridgerate", steps: [
      .init(id: .init(), description: "Now that everything is in the butter mixture, stir gently until just combined then refridgerate."),
    ]))
    try await sdc.updateRecipe(recipe)
    let recipeSDC4 = await sdc.retrieveRecipes().first
    XCTAssertEqual(recipe, recipeSDC4)
  }
  
  func testUpdateRecipeInvalidID() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let recipes = await sdc.retrieveRecipes()
    XCTAssertTrue(recipes.isEmpty)
    
    // Let's add an empty butter recipe.
    let id = Recipe.ID()
    var recipe = Recipe(id: id, name: "Butter")
    try await sdc.createRecipe(recipe)
    let recipeSDC1 = await sdc.retrieveRecipe(recipe.id)
    XCTAssertEqual(recipe, recipeSDC1)
    
    // Delete it.
    try await sdc.deleteRecipe(recipe.id)

    // Try to update the recipe.
    recipe.name = "Brown Butter"
    do {
      try await sdc.updateRecipe(recipe)
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.notFound)
    }
    let recipeSDC2 = await sdc.retrieveRecipe(recipe.id)
    XCTAssertNil(recipeSDC2)
    
  }
  
  func deleteRecipe() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let initrecipes = await sdc.retrieveRecipes()
    XCTAssertTrue(initrecipes.isEmpty)
    
    // Let's create some recipes and add them.
    let recipes: [Recipe] = (1...10).map {
      .init(id: .init(), name: "Recipe No. \($0)")
    }
    for recipe in recipes {
      try await sdc.createRecipe(recipe)
    }
    let recipes1 = await sdc.retrieveRecipes()
    XCTAssertEqual(recipes1, recipes)
    XCTAssertTrue(recipes1.count == 9)
    XCTAssertTrue(recipes.count == 9)
    
    // Let's delete one and check.
    try await sdc.deleteRecipe(recipes1.first!.id)
    let recipes2SDC = await sdc.retrieveRecipes()
    var recipes2 = recipes1
    recipes2.removeLast()
    XCTAssertEqual(recipes2SDC, recipes2)
    XCTAssertTrue(recipes2SDC.count == 8)
    XCTAssertTrue(recipes2.count == 8)
    
    // Repeat.
    try await sdc.deleteRecipe(recipes2.first!.id)
    let recipes3SDC = await sdc.retrieveRecipes()
    var recipes3 = recipes2
    recipes3.removeLast()
    XCTAssertEqual(recipes3SDC, recipes3)
    XCTAssertTrue(recipes3SDC.count == 7)
    XCTAssertTrue(recipes3.count == 7)
    
    // Repeat.
    try await sdc.deleteRecipe(recipes3[1].id)
    let recipes4SDC = await sdc.retrieveRecipes()
    var recipes4 = recipes3
    recipes4.remove(at: 1)
    XCTAssertEqual(recipes4SDC, recipes4)
    XCTAssertTrue(recipes4SDC.count == 6)
    XCTAssertTrue(recipes4.count == 6)
    
    // Delete the rest.
    for recipe in recipes3 {
      try await sdc.deleteRecipe(recipe.id)
    }
    let recipes5SDC = await sdc.retrieveRecipes()
    XCTAssertTrue(recipes5SDC.isEmpty)
  }
}
