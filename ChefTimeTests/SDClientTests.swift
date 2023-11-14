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
    
    // Let's add a complicated recipe:
    let recipe2 = Recipe.longMock
    try await sdc.createRecipe(recipe2)
    let newRecipes2 = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(newRecipes2.count == 2)
    XCTAssertEqual(recipe, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe.id })))
    dump(diff(recipe2, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe2.id }))))
    XCTAssertEqual(recipe2, try XCTUnwrap(newRecipes2.first(where: { $0.id == recipe2.id })))
  }
  
  func testCreateDupeRecipe() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let recipes = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(recipes.isEmpty)
    
    // Let's add an empty butter recipe.
    let recipe = Recipe(id: .init(), name: "Butter")
    try await sdc.createRecipe(recipe)
    let newRecipes = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(newRecipes.count == 1)
    XCTAssertTrue(newRecipes.first == recipe)
    
    // Lets try to add it again (dupe)
    try await sdc.createRecipe(recipe)
    let newRecipes2 = await sdc.retrieveRecipes(FetchDescriptor<SDRecipe>())
    XCTAssertTrue(newRecipes2.count == 1)
    XCTAssertTrue(newRecipes2.first == recipe)
  }
}
