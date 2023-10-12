import Foundation
import CoreData

// TODO: This needs to be actor isolated to prevent concurrent mutations.
// TODO: This could utilize writable keypath setters for more efficient mutations

// We need to fetch the user's root folders.
struct CoreDataClient {
  private let container: CoreDataPersistenceContainer
  
  init(inMemory: Bool = false) {
    self.container = .init(inMemory: inMemory)
  }
  
  func createFolder(_ folder: Folder) async -> Void {
    guard let _ = folder.toCoreFolder(container.viewContext)
    else { return }
    container.save()
  }
  
  func retrieveFolder(_ folderID: Folder.ID) async -> Folder? {
    let request = CoreFolder.fetchRequest()
    request.predicate = .init(format: "id == %@", folderID.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let coreFolder = response.first,
          let folder = coreFolder.toFolder()
    else { return nil }
    return folder
  }
  
  // TODO: Inspect this code performance because replacing recursive structure may be expensive
  // TODO: You can delete but not create a core folder, so this could be very bad
  func updateFolder(_ folder: Folder) async -> Void {
    let request = CoreFolder.fetchRequest()
    request.predicate = .init(format: "id == %@", folder.id.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let originalCoreFolder = response.first,
          folder.id.rawValue == originalCoreFolder.id
    else { return }

    let originalParentRef = originalCoreFolder.parentFolder
    container.viewContext.delete(originalCoreFolder)
    
    guard let newCoreFolder = folder.toCoreFolder(container.viewContext)
    else { return }
    newCoreFolder.parentFolder = originalParentRef
    container.save()
  }
  
  func createRecipe(_ recipe: Recipe) async -> Void {
    guard let _ = recipe.toCoreRecipe(container.viewContext)
    else { return }
    container.save()
  }
  
  func retrieveRecipe(_ recipeID: Recipe.ID) async -> Recipe? {
    let request = CoreRecipe.fetchRequest()
    request.predicate = .init(format: "id == %@", recipeID.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let coreRecipe = response.first,
          let recipe = coreRecipe.toRecipe()
    else { return nil }
    return recipe
  }
   
  // TODO: Setup relations
  // TODO: You can delete but not create a core recipe, so this could be very bad
  func updateRecipe(_ recipe: Recipe) async -> Void {
    let request = CoreRecipe.fetchRequest()
    request.predicate = .init(format: "id == %@", recipe.id.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let originalCoreRecipe = response.first,
          recipe.id.rawValue == originalCoreRecipe.id
    else { return }
    
    let originalParentRef = originalCoreRecipe.folder
    container.viewContext.delete(originalCoreRecipe)
    
    guard let newCoreRecipe = recipe.toCoreRecipe(container.viewContext)
    else { return }
    newCoreRecipe.folder = originalParentRef
    container.save()
  }
}

// MARK: - CoreDataPersistenceContainer
struct CoreDataPersistenceContainer {
  private let container: NSPersistentContainer
  
  var viewContext: NSManagedObjectContext {
    self.container.viewContext
  }
  
  func newBackgroundContext() -> NSManagedObjectContext {
    self.container.newBackgroundContext()
  }
  
  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "CoreModels")
    container.loadPersistentStores { _, error in
      if let error { fatalError("ERROR LOADING CORE DATA: \(error)") } // TODO: This should not nuke in production
      else { print("Successfully loaded Core Data") }
    }
    
    // Setup in-memory use according to this article: https://www.donnywals.com/setting-up-a-core-data-store-for-unit-tests/
    if inMemory {
      let description = NSPersistentStoreDescription()
      description.url = URL(fileURLWithPath: "/dev/null")
      container.persistentStoreDescriptions = [description]
    }
  }
  
  func save() {
    if !container.viewContext.hasChanges  { return }
    do {
      try container.viewContext.save()
    } catch {
      print("CORE DATA FAILED TO SAVE: \(error)")
    }
  }
  
}
