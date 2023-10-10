import Foundation
import ComposableArchitecture

struct Database {
  // MARK: - Folder CRUD
  let createFolder: @Sendable (Folder) async -> Void
  let retrieveFolder: @Sendable (Folder.ID) async -> Folder?
  let updateFolder: @Sendable (Folder) async -> Void
  
  // MARK: - Recipe CRUD
  let createRecipe: @Sendable (Recipe) async -> Void
  let retrieveRecipe: @Sendable (Recipe.ID) async -> Recipe?
  let updateRecipe: @Sendable (Recipe) async -> Void
  
  // MARK: - Other
  let deleteAll: @Sendable () async -> Void
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
