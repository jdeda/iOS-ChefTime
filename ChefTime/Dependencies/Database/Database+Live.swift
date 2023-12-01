import Foundation
import ComposableArchitecture
import CoreData

// MARK: - Database.livean
// Represents the production version of the database client.
extension Database {
  static let live = {
    let sdc = SDClient()!
    return Self(
      initializeDatabase: {
        await sdc.initializeDatabase()
      },
      retrieveRootFolders: {
        await sdc.retrieveRootFolders()
      },
      createFolder: { folder in
        try await sdc.createFolder(folder)
      },
      retrieveFolder: { folderID in
        return await sdc.retrieveFolder(folderID)
      },
      updateFolder: { folder in
        try await sdc.updateFolder(folder)
      },
      deleteFolder: { folderID in
        try await sdc.deleteFolder(folderID)
      },
      createRecipe: { recipe in
        try await sdc.createRecipe(recipe)
      },
      retrieveRecipe: { recipeID in
        await sdc.retrieveRecipe(recipeID)
      },
      updateRecipe: { recipe in
        try await sdc.updateRecipe(recipe)
      },
      deleteRecipe: { recipeID in
        try await sdc.deleteRecipe(recipeID)
      }
    )
  }()
}
