import Tagged
import Foundation
import ComposableArchitecture
import SwiftData

// MARK: - SDModel
/// Represents a container for recipes.
/// Folders are recursive over themselves and contain a list of recipes.
@Model
final class SDFolder: Identifiable, Equatable {
  let id: UUID
  
  var name: String
  
  @Attribute(.externalStorage)
  var imageData: SDData?
  
  @Relationship(deleteRule: .cascade, inverse: \SDFolder.parentFolder)
  var folders: [SDFolder]
  
  @Relationship(deleteRule: .cascade, inverse: \SDRecipe.parentFolder)
  var recipes: [SDRecipe]
  
  var folderType: Folder.FolderType
  
  var parentFolder: SDFolder?
  
  var positionPriority: Int?

  let creationDate: Date
  
  var lastEditDate: Date
    
  init(
    id: ID,
    name: String,
    imageData: SDData?,
    folders: [SDFolder],
    recipes: [SDRecipe],
    folderType: Folder.FolderType,
    parentFolder: SDFolder? = nil,
    positionPriority: Int?,
    creationDate: Date,
    lastEditDate: Date
  ) {
    self.id = id
    self.name = name
    self.imageData = imageData
    self.folders = folders
    self.recipes = recipes
    self.folderType = folderType
    self.parentFolder = parentFolder
    self.positionPriority = positionPriority
    self.creationDate = creationDate
    self.lastEditDate = lastEditDate
  }
  
  convenience init(_ folder: Folder, _ positionPriority: Int? = nil) {
    self.init(
      id: folder.id.rawValue,
      name: folder.name,
      imageData: folder.imageData.flatMap({SDData.init($0)}),
      folders: folder.folders.enumerated().map({SDFolder($0.element, $0.offset)}),
      recipes: folder.recipes.map(SDRecipe.init),
      folderType: folder.folderType,
      positionPriority: positionPriority,
      creationDate: folder.creationDate,
      lastEditDate: folder.lastEditDate
    )
  }
}


// MARK: - Model
/// Represents a container for recipes.
/// Folders are recursive over themselves and contain a list of recipes.
struct Folder: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var parentFolderID: Folder.ID?
  var name: String = ""
  var imageData: ImageData?
  var folders: IdentifiedArrayOf<Self> = []
  var recipes: IdentifiedArrayOf<Recipe> = []
  var folderType: FolderType = .user
  let creationDate: Date
  var lastEditDate: Date
  
  init(
    id: ID,
    parentFolderID: Folder.ID? = nil,
    name: String = "",
    imageData: ImageData? = nil,
    folders: IdentifiedArrayOf<Self> = [],
    recipes: IdentifiedArrayOf<Recipe> = [],
    folderType: FolderType = .user,
    creationDate: Date,
    lastEditDate: Date
  ) {
    self.id = id
    self.parentFolderID = parentFolderID
    self.name = name
    self.imageData = imageData
    self.folders = folders
    self.recipes = recipes
    self.folderType = folderType
    self.creationDate = creationDate
    self.lastEditDate = lastEditDate
  }
  
  init(_ sdFolder: SDFolder) {
    self.init(
      id: .init(rawValue: sdFolder.id),
      parentFolderID: nil,
      name: sdFolder.name,
      imageData: sdFolder.imageData.flatMap({ImageData.init($0)}),
      folders: .init(uniqueElements: sdFolder.folders.map(Folder.init)),
      recipes: .init(uniqueElements: sdFolder.recipes.map(Recipe.init)),
      folderType: sdFolder.folderType,
      creationDate: sdFolder.creationDate,
      lastEditDate: sdFolder.lastEditDate
    )
  }
}

extension Folder {
  enum FolderType: Equatable, Codable, CaseIterable {
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

// MARK: - Empty Mock.
extension Folder {
  static let emptyMock = Self(id: .init(), creationDate: .init(), lastEditDate: .init())
}

// MARK: - ShortMock
extension Folder {
  static let shortMock = Self(
    id: .init(),
    name: "My Best Recipes",
    folders: [],
    recipes: .init(uniqueElements: (1...10).map(generateRecipe)),
    creationDate: .init(), 
    lastEditDate: .init()
  )
}

// MARK: - LongMock
extension Folder {
  static let longMock = Self(
    id: .init(),
    name: "My Best Recipes",
    folders: .init(uniqueElements: (1...5).map(generateFolder)),
    recipes: .init(uniqueElements: (1...10).map(generateRecipe)),
    creationDate: .init(), 
    lastEditDate: .init()
  )
}

// MARK: - LongMock
extension Folder {
  static let giantMock: [Self] = (1...10).map(generateDeepFolder)
}


// MARK: - Mock Helpers
private func generateDeepFolder(_ num: Int) -> Folder {
  .init(
    id: .init(),
    name: "Folder No. \(num)",
    folders: .init(uniqueElements: (1...5).map(generateFolder)),
    recipes: .init(uniqueElements: (1...10).map(generateRecipe)),
    creationDate: .init(),
    lastEditDate: .init()
  )
}

private func generateFolder(_ num: Int) -> Folder {
  .init(
    id: .init(),
    name: "Folder No. \(num)",
    folders: [],
    recipes: .init(uniqueElements: (1...10).map(generateRecipe)),
    creationDate: .init(),
    lastEditDate: .init()
  )
}

private func generateRecipe(_ num: Int) -> Recipe {
  .init(
    id: .init(),
    name: "Double Cheese Burger No. \(num)",
    imageData: [
      .init(
        id: .init(),
        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_00", withExtension: "jpeg")!))!
      )!
    ],
    aboutSections: [
      .init(
        id: .init(),
        name: "Description",
        description: "A proper meat feast, this classical burger is just too good! Homemade buns and ground meat, served with your side of classic toppings, it makes a fantastic Friday night treat or cookout favorite."
      )
    ],
    ingredientSections: [
      .init(
        id: .init(),
        name: "Burger",
        ingredients: [
          .init(id: .init(), name: "Buns", amount: 1, measure: "store pack"),
          .init(id: .init(), name: "Frozen Beef Patties", amount: 1, measure: "lb"),
          .init(id: .init(), name: "Lettuce", amount: 2, measure: "leaves"),
          .init(id: .init(), name: "Tomato", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Onion", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Pickle", amount: 2, measure: "chips"),
          .init(id: .init(), name: "Ketchup", amount: 2, measure: "tbsp"),
          .init(id: .init(), name: "Mustard", amount: 2, measure: "tbsp")
        ]
      ),
    ],
    stepSections: [
      .init(id: .init(), name: "Burger", steps: [
        .init(
          id: .init(),
          description: "Toast the buns"
        ),
        .init(
          id: .init(),
          description: "Fry the burger patties"
        ),
        .init(
          id: .init(),
          description: "Assemble with toppings to your liking"
        ),
      ])
    ],
    creationDate: .init(),
    lastEditDate: .init()
  )
}

