import Tagged
import Foundation
import ComposableArchitecture
import SwiftData

/// Represents a container for recipes.
/// Folders are recursive over themselves and contain a list of recipes.
@Model
final class SDFolder: Identifiable, Equatable {
  
  @Attribute(.unique)
  let id: UUID
  
  var name: String
  var imageData: Data?

  @Relationship(deleteRule: .cascade, inverse: \SDFolder.parentFolder)
  var folders: [SDFolder]
  
  @Relationship(deleteRule: .cascade)
  var recipes: [SDRecipe]
  
  var folderType: Folder.FolderType
  var parentFolder: SDFolder?
  
  init(
    id: ID,
    name: String,
    imageData: Data?,
    folders: [SDFolder],
    recipes: [SDRecipe],
    folderType: Folder.FolderType,
    parentFolder: SDFolder?
  ) {
    self.id = id
    self.name = name
    self.imageData = imageData
    self.folders = folders
    self.recipes = recipes
    self.folderType = folderType
    self.parentFolder = parentFolder
  }
}
