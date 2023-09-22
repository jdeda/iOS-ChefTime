import Foundation
import CoreData

// We need to fetch the user's root folders.
struct CoreDataClient {
  private let container: CoreDataPersistenceContainer
  
  init(inMemory: Bool = false) {
    self.container = .init(inMemory: inMemory)
  }
  
  // CRUD
  func fetchUser() async -> User? {
    // Assume you are only ever going to have one user in this client's DB.
    // So we don't need a predicate of any sort.
    let request = CoreUser.fetchRequest()
    guard let response = try? container.viewContext.fetch(request),
          let user = response.first
    else { return nil }
    return user.toUser()
  }
  
  func updateUser(_ user: User) async -> Void {
    let request = CoreUser.fetchRequest()
    request.predicate = .init(format: "id == %@", user.id.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let coreUser = response.first
    else { return }
    coreUser.systemFolders = .init(array: user.systemFolders.compactMap { $0.toCoreFolder(container.viewContext) })
    coreUser.userFolders = .init(array: user.userFolders.compactMap { $0.toCoreFolder(container.viewContext) })
    container.save()
  }
  
  func updateRecipe(_ recipe: Recipe) async -> Void {
    guard let newCoreRecipe = recipe.toCoreRecipe(container.viewContext)
    else { return }
    
    let request = CoreRecipe.fetchRequest()
    request.predicate = .init(format: "id == %@", recipe.id.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let originalCoreRecipe = response.first
    else { return }
    
    // Copy the original ID and parent reference of the old recipe, then delete the old one
    // then replace the new recipe's id and parent reference with the old recipe's ones
    // then finally save all the changes.
    let originalID = originalCoreRecipe.id
    let originalParentRef = originalCoreRecipe.folder
    // It also may be possible we need to delete the parent's reference to a child and replace it with this one!
    container.viewContext.delete(originalCoreRecipe)
    newCoreRecipe.id = originalID
    newCoreRecipe.folder = originalParentRef
    container.save()
  }
  
  func updateFolder(_ folder: Folder) async -> Void {
    guard let newCoreFolder = folder.toCoreFolder(container.viewContext)
    else { return }
    
    let request = CoreFolder.fetchRequest()
    request.predicate = .init(format: "id == %@", folder.id.rawValue.uuidString)
    guard let response = try? container.viewContext.fetch(request),
          let originalCoreFolder = response.first
    else { return }
    
    // Copy the original ID and parent reference of the old recipe, then delete the old one
    // then replace the new recipe's id and parent reference with the old recipe's ones
    // then finally save all the changes.
    let originalID = originalCoreFolder.id
    let originalParentRef = originalCoreFolder.parentFolder
    // TODO: This needs to be checked and handled...
    // Must check if the folder being replaced is a root folder.
    // It also may be possible we need to delete the parent's reference to a child and replace it with this one!
    container.viewContext.delete(originalCoreFolder)
    newCoreFolder.id = originalID
    newCoreFolder.parentFolder = originalParentRef
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
    container = NSPersistentContainer(name: "ChefTime")
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
