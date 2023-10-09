import Foundation
import CoreData

// We need to fetch the user's root folders.
struct CoreDataClient {
  private let container: CoreDataPersistenceContainer
  
  init(inMemory: Bool = false) {
    self.container = .init(inMemory: inMemory)
  }
  
  // TODO: Setup relations
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
  func updateRecipe(_ recipe: Recipe) async -> Void {
    let request = CoreRecipe.fetchRequest()
    request.predicate = .init(format: "id == %@", recipe.id.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let originalCoreRecipe = response.first,
          recipe.id.rawValue == originalCoreRecipe.id
    else { return }
    
    // Copy the original ID and parent reference of the old recipe, then delete the old one
    // then replace the new recipe's id and parent reference with the old recipe's ones
    // then finally save all the changes.
    // It also may be possible we need to delete the parent's reference to a child and replace it with this one!
    let originalID = originalCoreRecipe.id
    let originalParentRef = originalCoreRecipe.folder
    container.viewContext.delete(originalCoreRecipe)
    
    guard let newCoreRecipe = recipe.toCoreRecipe(container.viewContext)
    else { return }
    newCoreRecipe.id = originalID
    newCoreRecipe.folder = originalParentRef
    container.save()
  }
//  // TODO: Setup relations
//  func updateRecipe(_ recipe: Recipe) async -> Void {
//    guard let newCoreRecipe = recipe.toCoreRecipe(container.viewContext)
//    else { return }
//
//    let request = CoreRecipe.fetchRequest()
//    request.predicate = .init(format: "id == %@", recipe.id.rawValue.uuidString)
//    guard let response = try? container.viewContext.fetch(request),
//          let originalCoreRecipe = response.first,
//          newCoreRecipe.id == originalCoreRecipe.id
//    else { return }
//
//    // Copy the original ID and parent reference of the old recipe, then delete the old one
//    // then replace the new recipe's id and parent reference with the old recipe's ones
//    // then finally save all the changes.
//    let originalID = originalCoreRecipe.id
//    let originalParentRef = originalCoreRecipe.folder
//    // It also may be possible we need to delete the parent's reference to a child and replace it with this one!
//    container.viewContext.delete(originalCoreRecipe)
//    newCoreRecipe.id = originalID
//    newCoreRecipe.folder = originalParentRef
//    container.save()
//  }
  
  func deleteAll() async {
    let request = CoreRecipe.fetchRequest()
    guard let response = try? container.viewContext.fetch(request)
    else { return }
    response.forEach { container.viewContext.delete($0) }
    container.viewContext.registeredObjects.forEach {
      container.viewContext.delete($0)
    }
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
