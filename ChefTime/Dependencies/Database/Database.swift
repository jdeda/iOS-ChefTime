import Foundation
import ComposableArchitecture

// TODO: - Make Sendable?
struct Database {
  let retrieveRootFolders: @Sendable () async -> [Folder]
  
  // MARK: - Folder CRUD
  let createFolder: @Sendable (Folder) async -> Void
  let retrieveFolder: @Sendable (Folder.ID) async -> Folder?
  let updateFolder: @Sendable (Folder) async -> Void
  let deleteFolder: @Sendable (Folder.ID) async -> Void
  
  // MARK: - Recipe CRUD
  let createRecipe: @Sendable (Recipe) async -> Void
  let retrieveRecipe: @Sendable (Recipe.ID) async -> Recipe?
  let updateRecipe: @Sendable (Recipe) async -> Void  
  let deleteRecipe: @Sendable (Recipe.ID) async -> Void
}

extension Database: DependencyKey {
  static var liveValue: Self = .live
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue}
  }
}
