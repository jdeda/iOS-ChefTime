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