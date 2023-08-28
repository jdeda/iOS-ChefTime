import Foundation
import ComposableArchitecture
import Tagged

/// Represents a container for recipes.
/// Folders are recursive over themselves and contain a list of recipes.
struct Folder: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var name: String = ""
  var folders: IdentifiedArrayOf<Self> = []
  var recipes: IdentifiedArrayOf<Recipe> = []
}
