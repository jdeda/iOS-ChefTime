import Foundation
import ComposableArchitecture
import Tagged

struct User: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  let id: ID
  
  var systemFolders: IdentifiedArrayOf<Folder> = []
  var userFolders: IdentifiedArrayOf<Folder> = []
}
