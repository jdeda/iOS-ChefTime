import Foundation
import ComposableArchitecture
import CoreData

extension Database {
  static let live = {
    let db = CoreDataClient(inMemory: false)
    return Self(
      createFolder: { folder in
        return await db.createFolder(folder)
      },
      retrieveFolder: { folderID in
        return await db.retrieveFolder(folderID)
      },
      updateFolder: { folder in
        return await db.updateFolder(folder)
      },
      createRecipe: { recipe in
        return await db.createRecipe(recipe)
      },
      retrieveRecipe: { recipeID in
        return await db.retrieveRecipe(recipeID)
      },
      updateRecipe: { recipe in
        return await db.updateRecipe(recipe)
      },
      deleteAll: {
        return await db.deleteAll()
      }
    )
  }()
}
