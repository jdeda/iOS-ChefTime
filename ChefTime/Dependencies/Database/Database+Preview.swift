import Foundation
import ComposableArchitecture
import CoreData
import SwiftUI

// TODO: Fix this to be easier to work with and work on device
// 1. Loading data and moving it to bundle should be very simple
// 2. Should work on device but not actually persist.

// Represents the XCode preview oriented version of the database client.
// Generates and utilizes mock data that resets on reinit.
extension Database {
  static let preview = {
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
