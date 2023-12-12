import Foundation
import ComposableArchitecture
import CoreData
import XCTestDynamicOverlay

// MARK: - Database.test
// Represents the testing version of the database client.
extension Database {
  static let test = {
    Self(
      initializeDatabase: unimplemented("Database.initializeDatabase"),
      retrieveRootFolders: unimplemented("Database.retrieveRootFolders"),
      createFolder: unimplemented("Database.createFolder"),
      retrieveFolder: unimplemented("Database.retrieveFolder"),
      updateFolder: unimplemented("Database.updateFolder"),
      deleteFolder: unimplemented("Database.deleteFolder"),
      createRecipe: unimplemented("Database.createRecipe"),
      retrieveRecipe: unimplemented("Database.retrieveRecipe"),
      updateRecipe: unimplemented("Database.updateRecipe"),
      deleteRecipe: unimplemented("Database.deleteRecipe"),
      searchRecipes: unimplemented("Database.searchRecipes")
    )
  }()
}
