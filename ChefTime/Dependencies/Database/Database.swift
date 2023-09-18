import Foundation
import ComposableArchitecture

struct Database {
  let fetchAllFolders: () -> AsyncStream<Folder>
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
