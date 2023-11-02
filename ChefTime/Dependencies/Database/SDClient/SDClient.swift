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
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
  }
  
  enum SDError: Equatable, Error {
    case failure
  }
  
  func retrieveRootFolders() -> [Folder] {
    print("SDClient", "retrieveRootFolders")
    let predicate = #Predicate<SDFolder> { $0.parentFolder == nil }
    let fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    let sdFolders = (try? modelContext.fetch(fetchDescriptor)) ?? []
    return sdFolders.map(Folder.init)
  }
  
  // MARK: - Folder CRUD
  func createFolder(_ folder: Folder) throws {
    print("SDClient", "createFolder")
    let sdFolder = SDFolder(folder)
    modelContext.insert(sdFolder)
    try modelContext.save()
    
    func linkSDFolder(_ sdFolder: SDFolder) {
      sdFolder.folders.forEach {
        $0.parentFolder = sdFolder
        linkSDFolder($0)
      }
      sdFolder.recipes.forEach {
        $0.parentFolder = sdFolder
      }
    }
    linkSDFolder(sdFolder)
    try modelContext.save()
  }
  
  func retrieveFolder(_ folderID: Folder.ID) -> Folder? {
    print("SDClient", "retrieveFolder")
    guard let sdFolder = _retrieveSDFolder(folderID)
    else { return nil }
    return Folder(sdFolder)
  }
  
  func updateFolder(_ folder: Folder) throws {
    print("SDClient", "updateFolder")
    printAll()
    try deleteFolder(folder.id)
    printAll()
    try createFolder(folder)
    printAll()
    try modelContext.save()
  }
  
  func deleteFolder(_ folderID: Folder.ID) throws {
    print("SDClient", "deleteFolder")
    guard let sdFolder = _retrieveSDFolder(folderID)
    else { throw SDError.failure }
    sdFolder.folders.forEach {
      try? self.deleteFolder(.init($0.id))
    }
    sdFolder.recipes.forEach {
      try? self.deleteRecipe(.init($0.id))
    }
    modelContext.delete(sdFolder)
    try modelContext.save()
    // Recursively delete all folders.
  }
  
  private func _retrieveSDFolder(_ folderID: Folder.ID) -> SDFolder? {
    print("SDClient", "_retrieveSDFolder")
    let predicate = #Predicate<SDFolder> { $0.id == folderID.rawValue }
    let fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    return try? modelContext.fetch(fetchDescriptor).first
  }
  
  // MARK: - Recipe CRUD
  func createRecipe(_ recipe: Recipe) throws {
    print("SDClient", "createRecipe")
    let sdRecipe = SDRecipe(recipe)
    modelContext.insert(sdRecipe)
    try modelContext.save()
  }
  
  func retrieveRecipe(_ recipeID: Recipe.ID) -> Recipe? {
    print("SDClient", "retrieveRecipe")
    guard let sdRecipe = _retrieveSDRecipe(recipeID.rawValue)
    else { return nil }
    return Recipe(sdRecipe)
  }
  
  func updateRecipe(_ recipe: Recipe) throws {
    print("SDClient", "updateRecipe")
    try deleteRecipe(recipe.id)
    try createRecipe(recipe)
    try modelContext.save()
  }
  
  func deleteRecipe(_ recipeID: Recipe.ID) throws {
    print("SDClient", "deleteRecipe")
    guard let sdRecipe = _retrieveSDRecipe(recipeID.rawValue)
    else { throw SDError.failure }
    sdRecipe.aboutSections.forEach { sdas in
      modelContext.delete(sdas)
    }
    sdRecipe.ingredientSections.forEach { sdis in
      sdis.ingredients.forEach { sdi in
        modelContext.delete(sdi)
      }
      modelContext.delete(sdis)
    }
    sdRecipe.stepSections.forEach { sdss in
      sdss.steps.forEach { sdi in
        modelContext.delete(sdi)
      }
      modelContext.delete(sdss)
    }
    modelContext.delete(sdRecipe)
    try modelContext.save()
  }
  
  private func _retrieveSDRecipe(_ recipeID: UUID) -> SDRecipe? {
    print("SDClient", "_retrieveSDRecipe")
    let predicate = #Predicate<SDRecipe> { $0.id == recipeID }
    let fetchDescriptor = FetchDescriptor<SDRecipe>(predicate: predicate)
    return try? modelContext.fetch(fetchDescriptor).first
  }
  
  func printAll() {
    let sdf = try! modelContext.fetch(FetchDescriptor<SDFolder>())
    print("SDFolder", sdf.count)
    print("SDFolder.parentFolder", sdf.compactMap(\.parentFolder).count)
    
    let sdr = try! modelContext.fetch(FetchDescriptor<SDRecipe>())
    print("SDRecipe", sdr.count)
    print("SDRecipe.parentFolder", sdr.compactMap(\.parentFolder).count)
    
    let sdas = try! modelContext.fetch(FetchDescriptor<SDRecipe.SDAboutSection>())
    print("SDAboutSection", sdas.count)
    print("SDAboutSection.parentRecipe", sdas.compactMap(\.parentRecipe).count)
    
    let sdis = try! modelContext.fetch(FetchDescriptor<SDRecipe.SDIngredientSection>())
    print("SDIngredientSection", sdis.count)
    print("SDIngredientSection.parentRecipe", sdis.compactMap(\.parentRecipe).count)
    
    let sdi = try! modelContext.fetch(FetchDescriptor<SDRecipe.SDIngredientSection.SDIngredient>())
    print("SDIngredient", sdi.count)
    print("SDIngredient.parentIngredientSection", sdi.compactMap(\.parentIngredientSection).count)
    
    let sdss = try! modelContext.fetch(FetchDescriptor<SDRecipe.SDStepSection>())
    print("SDStepSection", sdss.count)
    print("SDStepSection.parentRecipe", sdss.compactMap(\.parentRecipe).count)
    
    let sds = try! modelContext.fetch(FetchDescriptor<SDRecipe.SDStepSection.SDStep>())
    print("SDStep", sds.count)
    print("SDStep.parentStepSection", sds.compactMap(\.parentStepSection).count)
  }
}
