import Foundation
import SwiftData

actor SDClient: ModelActor {
  let modelContainer: ModelContainer
  let modelExecutor: ModelExecutor
  
  init?() {
    guard let modelContainer = try? ModelContainer(for: SDFolder.self, SDRecipe.self)
    else { return nil }
    self.modelContainer = modelContainer
    let context = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
  }
  
  enum SDError: Equatable, Error {
    case failure
  }
  
  func retrieveRootFolders() -> [Folder] {
    let predicate = #Predicate<SDFolder> { $0.parentFolder == nil }
    let fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    let sdFolders = (try? modelContext.fetch(fetchDescriptor)) ?? []
    return sdFolders.map(Folder.init)
  }
  
  // MARK: - Folder CRUD
  func createFolder(_ folder: Folder) throws {
    let sdFolder = SDFolder(folder)    
    modelContext.insert(sdFolder)
    try modelContext.save()
  }
  
  func retrieveFolder(_ folderID: UUID) -> Folder? {
    guard let sdFolder = _retrieveSDFolder(folderID)
    else { return nil }
    return Folder(sdFolder)
  }
  
  func updateFolder(_ folder: Folder) throws {
    try deleteFolder(folder)
    try createFolder(folder)
    try modelContext.save()
  }
  
  func deleteFolder(_ folder: Folder) throws {
    guard let sdFolder = _retrieveSDFolder(folder.id.rawValue)
    else { throw SDError.failure }
    modelContext.delete(sdFolder)
    try modelContext.save()
  }
  
  private func _retrieveSDFolder(_ folderID: UUID) -> SDFolder? {
    let predicate = #Predicate<SDFolder> { $0.id == folderID }
    let fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    return try? modelContext.fetch(fetchDescriptor).first
  }
  
  // MARK: - Recipe CRUD
  func createRecipe(_ recipe: Recipe) throws {
    let sdRecipe = SDRecipe(recipe)
    modelContext.insert(sdRecipe)
    try modelContext.save()
  }
  
  func retrieveRecipe(_ recipeID: UUID) -> Recipe? {
    guard let sdRecipe = _retrieveSDRecipe(recipeID)
    else { return nil }
    return Recipe(sdRecipe)
  }
  
  func updateRecipe(_ recipe: Recipe) throws {
    try deleteRecipe(recipe)
    try createRecipe(recipe)
    try modelContext.save()
  }
  
  func deleteRecipe(_ recipe: Recipe) throws {
    guard let sdRecipe = _retrieveSDRecipe(recipe.id.rawValue)
    else { throw SDError.failure }
    modelContext.delete(sdRecipe)
    try modelContext.save()
  }
  
  private func _retrieveSDRecipe(_ recipeID: UUID) -> SDRecipe? {
    let predicate = #Predicate<SDRecipe> { $0.id == recipeID }
    let fetchDescriptor = FetchDescriptor<SDRecipe>(predicate: predicate)
    return try? modelContext.fetch(fetchDescriptor).first
  }
}

//import Foundation
//import SwiftData
//
//struct SDClient {
//  let container: ModelContainer
//  let context: ModelContext
//
//  init?() {
//    guard let container = try? ModelContainer(for: SDRecipe.self)
//    else { return nil }
//    self.container = container
//    self.context = .init(self.container)
//  }
//
//  enum SDError: Equatable, Error {
//    case failure
//  }
//
//  func createRecipe(_ recipe: Recipe) throws {
//    let sdRecipe = SDRecipe(recipe)
//    context.insert(sdRecipe)
//    try context.save()
//  }
//
//  func retrieveRecipe(_ recipeID: UUID) -> Recipe? {
//    guard let sdRecipe = _retrieveSDRecipe(recipeID)
//    else { return nil }
//    return Recipe(sdRecipe)
//  }
//
//  func updateRecipe(_ recipe: Recipe) throws {
//    try deleteRecipe(recipe)
//    try createRecipe(recipe)
//    try context.save()
//  }
//
//  func deleteRecipe(_ recipe: Recipe) throws {
//    guard let sdRecipe = _retrieveSDRecipe(recipe.id.rawValue)
//    else { throw SDError.failure }
//    context.delete(sdRecipe)
//    try context.save()
//  }
//
//  private func _retrieveSDRecipe(_ recipeID: UUID) -> SDRecipe? {
//    let predicate = #Predicate<SDRecipe> { $0.id == recipeID }
//    let fetchDescriptor = FetchDescriptor<SDRecipe>(predicate: predicate)
//    return try? context.fetch(fetchDescriptor).first
//  }
//}
