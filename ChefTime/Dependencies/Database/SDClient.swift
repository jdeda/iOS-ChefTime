import Foundation
import SwiftData

// Client responsible for all SwiftData operations for the entire app.
// Performs basic CRUD operations on SDFolders and SDRecipes.
// Executes all operations on background thread via ModelActor.
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
  
  init?(_ url: URL) {
    guard let container = try? ModelContainer(for: SDFolder.self, SDRecipe.self, configurations: .init(url: url))
    else { return nil }
    self.modelContainer = container
    let context = ModelContext(container)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
  }
  
  enum SDError: Equatable, Error {
    case failure
    case notFound
    case duplicate
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
    // Check if a duplicate exists.
    let uuid = folder.id.rawValue // Putting this in the predicate causes runtime crash
    let predicate = #Predicate<SDFolder> { $0.id == uuid }
    var fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    fetchDescriptor.fetchLimit = 1
    fetchDescriptor.propertiesToFetch = [\.id]
    if let _ = try? modelContext.fetch(fetchDescriptor).first {
      throw SDError.duplicate
    }

    print("SDClient", "createFolder")
    let sdFolder = SDFolder(folder)
    modelContext.insert(sdFolder)
    do {try modelContext.save()}
    catch {
      dump(error)
      fatalError(error.localizedDescription)
    }
    
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
  
  func retrieveFolders(_ fetchDescriptor: FetchDescriptor<SDFolder> = .init()) -> [Folder] {
    print("SDClient", "retrieveFolders")
    let sdFolder = (try? modelContext.fetch(fetchDescriptor)) ?? []
    return sdFolder.map(Folder.init)
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
    else { throw SDError.notFound }
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
    // Check if a duplicate exists.
    let uuid = recipe.id.rawValue // Putting this in the predicate causes runtime crash
    let predicate = #Predicate<SDRecipe> { $0.id == uuid }
    var fetchDescriptor = FetchDescriptor<SDRecipe>(predicate: predicate)
    fetchDescriptor.fetchLimit = 1
    fetchDescriptor.propertiesToFetch = [\.id]
    if let _ = try? modelContext.fetch(fetchDescriptor).first {
      throw SDError.duplicate
    }
    print("SDClient", "createRecipe")
    let sdRecipe = SDRecipe(recipe)
    modelContext.insert(sdRecipe)
    try modelContext.save()
    
    sdRecipe.aboutSections.forEach { sdas in
      sdas.parentRecipe = sdRecipe
    }
    sdRecipe.ingredientSections.forEach { sdis in
      sdis.parentRecipe = sdRecipe
      sdis.ingredients.forEach { sdi in
        sdi.parentIngredientSection = sdis
      }
      modelContext.delete(sdis)
    }
    sdRecipe.stepSections.forEach { sdss in
      sdss.parentRecipe = sdRecipe
      sdss.steps.forEach { sds in
        sds.parentStepSection = sdss
      }
    }
    try modelContext.save()
  }
  
  func retrieveRecipe(_ recipeID: Recipe.ID) -> Recipe? {
    print("SDClient", "retrieveRecipe")
    guard let sdRecipe = _retrieveSDRecipe(recipeID.rawValue)
    else { return nil }
    return Recipe(sdRecipe)
  }
  
  func retrieveRecipes(_ fetchDescriptor: FetchDescriptor<SDRecipe> = .init()) -> [Recipe] {
    print("SDClient", "retrieveRecipes")
    let sdRecipes = (try? modelContext.fetch(fetchDescriptor)) ?? []
    return sdRecipes.map(Recipe.init)
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
    else { throw SDError.notFound }
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
