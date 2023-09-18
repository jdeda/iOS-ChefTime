import Foundation
import ComposableArchitecture

extension Database {
  static let live = Self(
    fetchAllFolders: {
      .init { continuation in
        
      }
    }
  )
}

//import Foundation
//import CoreData
//import IdentifiedCollections
//
/////
///// Manages CoreData directly, supporting a static instance, and CRUD operations.
/////
//struct CoreDataManager {
//  static let shared = CoreDataManager()
//
//  let container: NSPersistentContainer
//  var canUndo: Bool { container.viewContext.undoManager?.canUndo ?? false }
//  var canRedo: Bool { container.viewContext.undoManager?.canRedo ?? false }
//
//  init() {
//    container = NSPersistentContainer(name: "CoreTodo")
//    container.loadPersistentStores { _, error in
//      if let error { fatalError("ERROR LOADING CORE DATA: \(error)") }
//      else { print("Successfully loaded Core Data") }
//    }
//    container.viewContext.undoManager = .init()
//    container.viewContext.retainsRegisteredObjects = true
//  }
//
//  private func save() {
//    if !container.viewContext.hasChanges  { return }
//    do {
//      try container.viewContext.save()
//    } catch {
//      print("CORE DATA FAILED TO SAVE: \(error)")
//    }
//  }
//
//  func resetAll() {
//    deleteAll()
//    container.viewContext.undoManager = .init()
//  }
//  
//  private func deleteAll() {
//    let request = NSFetchRequest<CoreTodo>(entityName: "CoreTodo")
//    guard let response = try? container.viewContext.fetch(request)
//    else { return }
//    response.forEach { container.viewContext.delete($0) }
//    save()
//  }
//
//  func fetch() -> [Todo]? {
//    let request = NSFetchRequest<CoreTodo>(entityName: "CoreTodo")
//    guard let response = try? container.viewContext.fetch(request)
//    else { return nil }
//    return response.compactMap { coreTodo in
//      guard let id = coreTodo.id,
//            let description = coreTodo.body
//      else { return nil }
//      return Todo(
//        id: .init(id),
//        description: description,
//        isComplete: coreTodo.isComplete
//      )
//    }
//    .sorted(by: { $0.id.rawValue.uuidString > $1.id.rawValue.uuidString })
//  }
//  
//  func add(_ newTodo: Todo) {
//    container.viewContext.undoManager!.beginUndoGrouping()
//    let coreTodo = CoreTodo(context: container.viewContext)
//    coreTodo.id = newTodo.id.rawValue
//    coreTodo.body = newTodo.description
//    coreTodo.isComplete = newTodo.isComplete
//    container.viewContext.insert(coreTodo)
//    save()
//    container.viewContext.undoManager!.endUndoGrouping()
//  }
//  
//  func remove(_ todo: Todo) {
//    container.viewContext.undoManager!.beginUndoGrouping()
//    let cds = Array(container.viewContext.registeredObjects) as! [CoreTodo]
//    if let coreTodo = cds.first(where: { $0.id == todo.id.rawValue }) {
//      container.viewContext.delete(coreTodo)
//      save()
//    }
//    else {
//      print("CORE DATA FAILED TO REMOVE: \(todo)")
//    }
//    container.viewContext.undoManager!.endUndoGrouping()
//  }
//  
//  func update(_ todo: Todo) {
//    container.viewContext.undoManager!.beginUndoGrouping()
//    let cds = Array(container.viewContext.registeredObjects) as! [CoreTodo]
//    if let cd = cds.first(where: { $0.id == todo.id.rawValue }) {
//      cd.isComplete = todo.isComplete
//      cd.body = todo.description
//      save()
//    }
//    container.viewContext.undoManager!.endUndoGrouping()
//  }
//  
//  func update(_ todos: [Todo]) {
//    container.viewContext.undoManager!.beginUndoGrouping()
//    let cds = Array(container.viewContext.registeredObjects) as! [CoreTodo]
//    cds.forEach(container.viewContext.delete)
//    todos.forEach { todo in
//      let coreTodo = CoreTodo(context: container.viewContext)
//      coreTodo.id = todo.id.rawValue
//      coreTodo.body = todo.description
//      coreTodo.isComplete = todo.isComplete
//      container.viewContext.insert(coreTodo)
//    }
//    save()
//    container.viewContext.undoManager!.endUndoGrouping()
//  }
//  
//  func undo() {
//    container.viewContext.undoManager!.undo()
//    save()
//  }
//  
//  func redo() {
//    container.viewContext.undoManager!.redo()
//    save()
//  }
//}
