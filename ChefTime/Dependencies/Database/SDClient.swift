import Foundation
import SwiftData
import ComposableArchitecture
import Tagged

// Client responsible for all SwiftData operations for the entire app.
// Performs basic CRUD operations on SDFolders and SDRecipes.
// Executes all operations on background thread via ModelActor.
actor SDClient: ModelActor {
  let modelContainer: ModelContainer
  let modelExecutor: ModelExecutor
  private(set) var didInitStore: Bool
  
  init?() {
    guard let modelContainer = try? ModelContainer(for: SDFolder.self, SDRecipe.self)
    else { return nil }
    self.modelContainer = modelContainer
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    self.didInitStore = false
  }
  
  init?(_ url: URL) {
    let container = try! ModelContainer(for: SDFolder.self, SDRecipe.self, configurations: .init(url: url))
//    guard let container = try? ModelContainer(for: SDFolder.self, SDRecipe.self, configurations: .init(url: url))
//    else { return nil }
    self.modelContainer = container
    let context = ModelContext(container)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    self.didInitStore = false
  }
  
  enum SDError: Equatable, Error {
    case failure
    case notFound
    case duplicate
  }
  
  // Adds entities to the database if and only if the store is empty.
  func initializeDatabase() async {
    print("SDClient", "initializeDatabase")
    guard !self.didInitStore 
    else {
      print("SDClient", "initializeDatabase already done ...")
      return
    }
    let folderFD: FetchDescriptor<SDFolder> = {
      var fd = FetchDescriptor<SDFolder>()
//      fd.fetchLimit = 1
      fd.propertiesToFetch = [\.id]
      return fd
    }()
    let recipeFD: FetchDescriptor<SDRecipe> = {
      var fd = FetchDescriptor<SDRecipe>()
//      fd.fetchLimit = 1
      fd.propertiesToFetch = [\.id]
      return fd
    }()
    let foldersCount = try! self.modelContext.fetchCount(folderFD)
    let recipesCount = try! self.modelContext.fetchCount(recipeFD)
    guard foldersCount == 0 && recipesCount == 0
    else {
      print("SDClient", "initializeDatabase already done ...")
      self.didInitStore = true
      return
    }
    
    do {
      let gen = MockDataGenerator()
      let folders = await gen.generateMockFolders()
      for folder in folders {
        try self.createFolder(folder)
      }
      print("SDClient", "initializeDatabase succeeded")
      self.didInitStore = true
    } catch {
      print("SDClient", "initializeDatabase failed: \(error.localizedDescription)")
    }
  }

  func retrieveRootFolders() -> [Folder] {
    print("SDClient", "retrieveRootFolders")
    let predicate = #Predicate<SDFolder> { $0.parentFolder == nil }
    let fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    let sdFolders = (try? self.modelContext.fetch(fetchDescriptor)) ?? []
    return sdFolders.map(Folder.init)
  }
  
  // MARK: - Folder CRUD
  func createFolder(_ folder: Folder) throws {
    print("SDClient", "createFolder")
    if self._containsDuplicateIDs(folder: folder) {
      throw SDError.duplicate // TODO: Need to check all child persistent model IDS...
    }
    
    // TODO: You could replace the value if it already exists e.g. upsert
    /// What happens if we create folderA and folderB. We move folderB into folderA. Now we have 2 folderBs.
    /// We need to prevent that from happening, so we can upsert.

    /// Sadly we have to do manual upserts because CloudKit doesn't allow upserting. So we have to do a lot of brute force work:
    /// 1. Iterate over all child PModels and if they already exist, delete them (because we will replace them)
    /// 2. Convert the Model to PModel
    let sdFolder = SDFolder(folder)
    self.modelContext.insert(sdFolder)
    try self.modelContext.save()
    self._linkSDFolder(sdFolder)
    try self.modelContext.save()
  }
  
  func retrieveFolder(_ folderID: Folder.ID) -> Folder? {
    print("SDClient", "retrieveFolder")
    guard let sdFolder = self._retrieveSDFolder(folderID)
    else { return nil }
    return Folder(sdFolder)
  }
  
  func retrieveFolders(_ fetchDescriptor: FetchDescriptor<SDFolder> = .init()) -> [Folder] {
    print("SDClient", "retrieveFolders")
    let sdFolder = (try? self.modelContext.fetch(fetchDescriptor)) ?? []
    return sdFolder.map(Folder.init)
  }
  
  func updateFolder(_ folder: Folder) throws {
    print("SDClient", "updateFolder")
    guard let original = self._retrieveSDFolder(folder.id) else { throw SDError.notFound }
    let originalFolder = Folder(original)
    try self.deleteFolder(folder.id)
    do {
      try self.createFolder(folder)
    }
    catch {
      try self.createFolder(originalFolder)
      throw error
    }
    try self.modelContext.save()
  }
  
  func deleteFolder(_ folderID: Folder.ID) throws {
    print("SDClient", "deleteFolder")
    guard let sdFolder = self._retrieveSDFolder(folderID)
    else { throw SDError.notFound }
    sdFolder.folders.forEach {
      try? self.deleteFolder(.init($0.id))
    }
    sdFolder.recipes.forEach {
      try? self.deleteRecipe(.init($0.id))
    }
    self.modelContext.delete(sdFolder)
    try self.modelContext.save()
  }
  
  // MARK: - Recipe CRUD
  func createRecipe(_ recipe: Recipe) throws {
    print("SDClient", "createRecipe")
    if self._containsDuplicateIDs(recipe: recipe) {
      throw SDError.duplicate // TODO: Need to check all child persistent model IDS...
    }
    let sdRecipe = SDRecipe(recipe)
    self.modelContext.insert(sdRecipe)
    try self.modelContext.save()
    self._linkSDRecipe(sdRecipe)
    try self.modelContext.save()
  }
  
  func retrieveRecipe(_ recipeID: Recipe.ID) -> Recipe? {
    print("SDClient", "retrieveRecipe")
    print(self.retrieveRecipes().map(\.id.rawValue))
    guard let sdRecipe = self._retrieveSDRecipe(recipeID)
    else { return nil }
    return Recipe(sdRecipe)
  }
  
  func retrieveRecipes(_ fetchDescriptor: FetchDescriptor<SDRecipe> = .init()) -> [Recipe] {
    print("SDClient", "retrieveRecipes")
    let sdRecipes = (try? self.modelContext.fetch(fetchDescriptor)) ?? []
    return sdRecipes.map(Recipe.init)
  }
  
  func updateRecipe(_ recipe: Recipe) throws {
    print("SDClient", "updateRecipe")
    guard let original = self._retrieveSDRecipe(recipe.id) else { throw SDError.notFound }
    let originalRecipe = Recipe(original)
    try self.deleteRecipe(recipe.id)
    do {
      try self.createRecipe(recipe)
    }
    catch {
      try self.createRecipe(originalRecipe)
      throw error
    }
    try self.modelContext.save()
  }
  
  func deleteRecipe(_ recipeID: Recipe.ID) throws {
    print("SDClient", "deleteRecipe")
    guard let sdRecipe = self._retrieveSDRecipe(recipeID)
    else { throw SDError.notFound }
    sdRecipe.aboutSections.forEach { sdas in
      self.modelContext.delete(sdas)
    }
    sdRecipe.ingredientSections.forEach { sdis in
      sdis.ingredients.forEach { sdi in
        self.modelContext.delete(sdi)
      }
      self.modelContext.delete(sdis)
    }
    sdRecipe.stepSections.forEach { sdss in
      sdss.steps.forEach { sdi in
        self.modelContext.delete(sdi)
      }
      self.modelContext.delete(sdss)
    }
    self.modelContext.delete(sdRecipe)
    try self.modelContext.save()
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

// MARK: - Private retrieve methods for checking duplicate PersistentModel IDs.
extension SDClient {
  private func _containsDuplicateIDs(folder: Folder) -> Bool {
    guard !self._isDuplicateFolderID(folder.id) else { return true }
    for folder in folder.folders {
      guard !self._containsDuplicateIDs(folder: folder) else { return true }
    }
    for recipe in folder.recipes {
      guard !self._containsDuplicateIDs(recipe: recipe) else { return true }
    }
    return false
  }
  
  private func _containsDuplicateIDs(recipe: Recipe) -> Bool {
    guard !self._isDuplicateRecipeID(recipe.id) else { return true }
    return false
  }
  
  private func _isDuplicateFolderID(_ folderID: Folder.ID) -> Bool {
    let uuid = folderID.rawValue // Putting this in the predicate causes runtime crash
    let predicate = #Predicate<SDFolder> { $0.id == uuid }
    var fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    fetchDescriptor.fetchLimit = 1
    fetchDescriptor.propertiesToFetch = [\.id]
    if let fetched_uuid = try? modelContext.fetch(fetchDescriptor).first?.id {
      return fetched_uuid == uuid
    }
    return false
  }
  
  private func _isDuplicateRecipeID(_ recipeID: Recipe.ID) -> Bool {
    let uuid = recipeID.rawValue // Putting this in the predicate causes runtime crash
    let predicate = #Predicate<SDRecipe> { $0.id == uuid }
    var fetchDescriptor = FetchDescriptor<SDRecipe>(predicate: predicate)
    fetchDescriptor.fetchLimit = 1
    fetchDescriptor.propertiesToFetch = [\.id]
    if let fetched_uuid = try? modelContext.fetch(fetchDescriptor).first?.id {
      return fetched_uuid == uuid
    }
    return false
  }
}

// MARK: - Private retrieve methods for fetching PersistentModels by their ID
extension SDClient {
  private func _retrieveSDFolder(_ folderID: Folder.ID) -> SDFolder? {
    print("SDClient", "_retrieveSDFolder")
    let predicate = #Predicate<SDFolder> { $0.id == folderID.rawValue }
    let fetchDescriptor = FetchDescriptor<SDFolder>(predicate: predicate)
    return try? self.modelContext.fetch(fetchDescriptor).first
  }
  
  private func _retrieveSDRecipe(_ recipeID: Recipe.ID) -> SDRecipe? {
    print("SDClient", "_retrieveSDRecipe")
    let predicate = #Predicate<SDRecipe> { $0.id == recipeID.rawValue }
    let fetchDescriptor = FetchDescriptor<SDRecipe>(predicate: predicate)
    return try? self.modelContext.fetch(fetchDescriptor).first
  }
}

// MARK: - Private link methods for interlinking PersistentModel parent-child relations.
extension SDClient {
  private func _linkSDFolder(_ sdFolder: SDFolder) {
    sdFolder.folders.forEach {
      $0.parentFolder = sdFolder
      self._linkSDFolder($0)
    }
    sdFolder.recipes.forEach {
      $0.parentFolder = sdFolder
      self._linkSDRecipe($0)
    }
  }
  
  private func _linkSDRecipe(_ sdRecipe: SDRecipe) {
    sdRecipe.aboutSections.forEach { sdas in
      sdas.parentRecipe = sdRecipe
    }
    sdRecipe.ingredientSections.forEach { sdis in
      sdis.parentRecipe = sdRecipe
      sdis.ingredients.forEach { sdi in
        sdi.parentIngredientSection = sdis
      }
    }
    sdRecipe.stepSections.forEach { sdss in
      sdss.parentRecipe = sdRecipe
      sdss.steps.forEach { sds in
        sds.parentStepSection = sdss
      }
    }
  }
}

fileprivate struct MockDataGenerator {
  // Fetches folder models from local JSON files.
  fileprivate func generateMockFolders() async -> [Folder] {
    let fetchFolders: (URL) async -> [Folder] = {
      let rootSystemURL = $0
      let contents = try! FileManager.default.contentsOfDirectory(
        at: rootSystemURL,
        includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
        options: .skipsHiddenFiles
      )
      
      var folders = [Folder]()
      for url in contents {
        guard let folder = await fetchFolder(at: url)
        else { continue }
        folders.append(folder)
      }
      return folders
    }
    
    let root = URL(filePath: "/Users/jessededa/Downloads/JSON")
    let f1 = await fetchFolders(root.appendingPathComponent("system"))
    let f2 = await fetchFolders(root.appendingPathComponent("user"))
    return f1 + f2
  }
  
  // TODO: Migrate your old data to the new data, including new dates!
  // Fetches folder model from local JSON file. Assume directory is a user folder.
  fileprivate func fetchFolder(at directoryURL: URL) async -> Folder? {
    guard let contents = try? FileManager.default.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
      options: .skipsHiddenFiles
    )
    else { return nil }
    
    var folder = Folder(
      id: .init(),
      name: directoryURL.lastPathComponent, folderType: .user,
      creationDate: .init(),
      lastEditDate: .init()
    )
    for url in contents {
      if url.hasDirectoryPath {
        guard let childFolder = await fetchFolder(at: url)
        else { continue }
        
        if folder.imageData == nil {
          folder.imageData = childFolder.imageData
        }
        folder.folders.append(childFolder)
      }
      else if url.pathExtension.lowercased() == "json" {
        guard let recipe = await fetchRecipe(at: url)
        else { continue }
        folder.recipes.append(recipe)
        folder.name = folder.name.capitalized
        if folder.imageData == nil {
          folder.imageData = recipe.imageData.first
        }
      }
      else { continue }
    }
    if folder.name.lowercased() == "standard" {
      
    }
    folder.name = folder.name.capitalized
    if folder.imageData == nil {
      if let imageData = folder.recipes.first(where: { $0.imageData.first != nil })?.imageData.first {
        folder.imageData = imageData
      }
    }
    return folder
  }
  
  // Fetches recipe model from local JSON file.
  fileprivate func fetchRecipe(at url: URL) async -> Recipe? {
    guard let data = try? Data(contentsOf: url),
          let recipeV0 = try? JSONDecoder().decode(RecipeV0.self, from: data)
    else { return nil }
    let recipe = Recipe.init(
      id: .init(rawValue: recipeV0.id.rawValue),
      name: recipeV0.name,
      imageData: recipeV0.imageData,
      aboutSections: recipeV0.aboutSections,
      ingredientSections: recipeV0.ingredientSections,
      stepSections: recipeV0.stepSections,
      creationDate: .init(),
      lastEditDate: .init()
    )
    return recipe
  }
  
  // Reads and writes recipe to disk given fileName and fileExtension.
  fileprivate struct ReadWriteIO {
    let fileName: String
    let fileExtension: String
    
    var fileURL: URL {
      Bundle.main.url(forResource: fileName, withExtension: fileExtension)!
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
  
  struct RecipeV0: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var imageData: IdentifiedArrayOf<ImageData> = []
    var aboutSections: IdentifiedArrayOf<Recipe.AboutSection> = []
    var ingredientSections: IdentifiedArrayOf<Recipe.IngredientSection> = []
    var stepSections: IdentifiedArrayOf<Recipe.StepSection> = []
    
    init(
      id: ID,
      name: String = "",
      imageData: IdentifiedArrayOf<ImageData> = [],
      aboutSections: IdentifiedArrayOf<Recipe.AboutSection> = [],
      ingredientSections: IdentifiedArrayOf<Recipe.IngredientSection> = [],
      stepSections: IdentifiedArrayOf<Recipe.StepSection> = []
    ) {
      self.id = id
      self.name = name
      self.imageData = imageData
      self.aboutSections = aboutSections
      self.ingredientSections = ingredientSections
      self.stepSections = stepSections
    }
  }
}
