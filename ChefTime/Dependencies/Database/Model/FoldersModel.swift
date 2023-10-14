import Foundation
import ComposableArchitecture
import Tagged

// MARK: - Model
/// Represents a container for recipes.
/// Folders are recursive over themselves and contain a list of recipes.
struct Folders: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var systemFolders: [Folder]
  var userFolders: [Folder]
}

// MARK: - Description
/// User can have two types of folders:
/// 1. SystemFolder
///   - All Folder (Derived)
///   - Favorites Folder (Derived)
///   - Shared Folder (Derived)
///   - Recently Deleted Folder (Derived)
/// 2. UserFolder
