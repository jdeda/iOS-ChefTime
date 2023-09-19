import Foundation
import ComposableArchitecture
import CoreData

extension Database {
  static let live = {
    let db = CoreDataClient(inMemory: false)
    return Self(
      fetchUser: {
        return await db.fetchUser()
      }
    )
  }()
}
