import Foundation
import ComposableArchitecture
import CoreData

extension Database {
  static let live = {
    let db = CoreDataClient(inMemory: false)
    return Self(
      fetchUser: {
        return await db.fetchUser()
      },
      updateUser: { user in
        return await db.updateUser(user)
      },
      updateRecipe: { recipe in
        return await db.updateRecipe(recipe)
      },
      updateFolder: { folder in
        return await db.updateFolder(folder)
      }
    )
  }()
}
