import Foundation
import ComposableArchitecture

// TODO: - Make Sendable?
struct Database {
  var initializeDatabase: @Sendable () async -> Void
  
  var retrieveRootFolders: @Sendable () async -> [Folder]
  
  var createFolder: @Sendable (Folder) async throws -> Void
  var retrieveFolder: @Sendable (Folder.ID) async -> Folder?
  var updateFolder: @Sendable (Folder) async throws -> Void
  var deleteFolder: @Sendable (Folder.ID) async throws -> Void
  
  var createRecipe: @Sendable (Recipe) async throws -> Void
  var retrieveRecipe: @Sendable (Recipe.ID) async -> Recipe?
  var updateRecipe: @Sendable (Recipe) async throws -> Void
  var deleteRecipe: @Sendable (Recipe.ID) async throws -> Void
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
