import Foundation
import ComposableArchitecture
import Tagged

/// Represents a container for recipes.
/// Folders are recursive over themselves and contain a list of recipes.
struct Folder: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var name: String = ""
  var imageData: ImageData?
  var folders: IdentifiedArrayOf<Self> = []
  var recipes: IdentifiedArrayOf<Recipe> = []
  var folderType: FolderType = .user
}

extension Folder {
  enum FolderType: Equatable, Codable {
    case systemAll
    case systemStandard
    case systemRecentlyDeleted
    case user
    
    var isSystem: Bool {
      switch self {
      case .systemAll, .systemStandard, .systemRecentlyDeleted:
        return true
      case .user:
        return false
      }
    }
  }
}
