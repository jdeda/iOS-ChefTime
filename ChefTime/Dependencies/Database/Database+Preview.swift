import Foundation
import ComposableArchitecture
import CoreData
import SwiftUI

// TODO: Fix this to be easier to work with and work on device
// 1. Loading data and moving it to bundle should be very simple
// 2. Should work on device but not actually persist.

// MARK: - May be better if DB files existed and were reset every time this instance is copied/initialized.
// That way we don't have to load, parse, stuff, all our data every single time we copy or init this.

/// Represents the XCode preview oriented version of the database client.
/// Generates and utilizes mock data that resets on reinit.
///
/// Checks and initializes the DB with mock data every method call if and only if the DB is empty.
/// This is to provide an easier and smoother experience for all features that depend on this client
/// to not have to call initializeDatabase() in their preview just to make sure they have mock data.

extension Database {
  static let preview = {
    // Storing our DB here puts everything in-memory, and will completely reset upon deinit.
    let url = URL(fileURLWithPath: "dev/null")
    let sdc = SDClient(url)!
    return Self(
      initializeDatabase: {
        await sdc.initializeDatabase()
      },
      retrieveRootFolders: {
        await sdc.initializeDatabase()
        return await sdc.retrieveRootFolders()
      },
      createFolder: { folder in
        await sdc.initializeDatabase()
        try await sdc.createFolder(folder)
      },
      retrieveFolder: { folderID in
        await sdc.initializeDatabase()
        return await sdc.retrieveFolder(folderID)
      },
      updateFolder: { folder in
        await sdc.initializeDatabase()
        try await sdc.updateFolder(folder)
      },
      deleteFolder: { folderID in
        await sdc.initializeDatabase()
        try await sdc.deleteFolder(folderID)
      },
      createRecipe: { recipe in
        await sdc.initializeDatabase()
        try await sdc.createRecipe(recipe)
      },
      retrieveRecipe: { recipeID in
        await sdc.initializeDatabase()
        return await sdc.retrieveRecipe(recipeID)
      },
      updateRecipe: { recipe in
        await sdc.initializeDatabase()
        try await sdc.updateRecipe(recipe)
      },
      deleteRecipe: { recipeID in
        await sdc.initializeDatabase()
        try await sdc.deleteRecipe(recipeID)
      }
    )
  }()
}
