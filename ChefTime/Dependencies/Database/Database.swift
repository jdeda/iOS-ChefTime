import Foundation
import ComposableArchitecture

struct Database {
  let fetchUser: @Sendable () async -> User?
  let updateUser: @Sendable (User) async -> Void
  let updateRecipe: @Sendable (Recipe) async -> Void
  let updateFolder: @Sendable (Folder) async -> Void
}

extension Database: DependencyKey {
  static var liveValue: Self = .live
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue}
  }
}
