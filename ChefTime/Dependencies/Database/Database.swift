import Foundation
import ComposableArchitecture

struct Database {
  let createRecipe: @Sendable (Recipe) async -> Void
  let retrieveRecipe: @Sendable (Recipe.ID) async -> Recipe?
  let updateRecipe: @Sendable (Recipe) async -> Void
  let deleteAll: @Sendable () async -> Void
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
