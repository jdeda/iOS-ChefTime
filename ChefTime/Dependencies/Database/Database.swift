import Foundation
import ComposableArchitecture

// TODO: - Make Sendable?
struct Database {
  var retrieveRootFolders: @Sendable () async -> [Folder]
  
  // MARK: - Folder CRUD
  var createFolder: @Sendable (Folder) async -> Void
  var retrieveFolder: @Sendable (Folder.ID) async -> Folder?
  var updateFolder: @Sendable (Folder) async -> Void
  var deleteFolder: @Sendable (Folder.ID) async -> Void
  
  // MARK: - Recipe CRUD
  var createRecipe: @Sendable (Recipe) async -> Void
  var retrieveRecipe: @Sendable (Recipe.ID) async -> Recipe?
  var updateRecipe: @Sendable (Recipe) async -> Void
  var deleteRecipe: @Sendable (Recipe.ID) async -> Void
}

extension Database: DependencyKey {
  static let liveValue = Self.live
  static let previewValue = Self.preview
  static let testValue = Self.test
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue}
  }
}
