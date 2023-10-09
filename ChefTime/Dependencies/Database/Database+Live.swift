import Foundation
import ComposableArchitecture
import CoreData

extension Database {
  static let live = {
    let db = CoreDataClient(inMemory: false)
    return Self(
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
