import Foundation
import ComposableArchitecture
import CoreData

// MARK: - Database.live
// Represents the production version of the database client.
extension Database {
  static let live = {
    let sdc = SDClient()! // MARK: - If this fail the app should be obliterated.
    return Self(
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
