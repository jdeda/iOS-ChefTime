import Foundation
import ComposableArchitecture
import CoreData
import SwiftUI

// Represents the XCode preview oriented version of the database client.
// Generates and utilizes mock data that resets on reinit.
extension Database {
  static let preview = {
    let source = Bundle.main.url(forResource: "sd_mock", withExtension: "store")!
    let original = Bundle.main.url(forResource: "sd_mock_original", withExtension: "store")!
    _ = try! FileManager.default.replaceItemAt(source, withItemAt: original)
    let sdc = SDClient(source)!
    
    return Self(
      retrieveRootFolders: {
        await sdc.retrieveRootFolders()
      },
      createFolder: { folder in
        try await sdc.createFolder(folder)
      },
      retrieveFolder: { folderID in
        return await sdc.retrieveFolder(folderID)
      },
      updateFolder: { folder in
        try await sdc.updateFolder(folder)
      },
      deleteFolder: { folderID in
        try await sdc.deleteFolder(folderID)
      },
      createRecipe: { recipe in
        try await sdc.createRecipe(recipe)
      },
      retrieveRecipe: { recipeID in
        await sdc.retrieveRecipe(recipeID)
      },
      updateRecipe: { recipe in
        try await sdc.updateRecipe(recipe)
      },
      deleteRecipe: { recipeID in
        try await sdc.deleteRecipe(recipeID)
      }
    )
  }()
}

// Used for creating SwiftData stack store with folders fetched from local JSON files.
struct LoadDBView: View {
  var body: some View {
    Text("Load View")
      .task {
        let folders = await generateMockFolders()
        let db = Database.live
        for folder in folders {
          try? await db.createFolder(folder)
        }
        print("Done")
      }
  }
}

// Fetches folder models from local JSON files.
fileprivate func generateMockFolders() async -> [Folder] {
  let fetchFolders: (String) async -> [Folder] = {
    let rootSystemURL = URL(string: $0)!
    let contents = try! FileManager.default.contentsOfDirectory(
      at: rootSystemURL,
      includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
      options: .skipsHiddenFiles
    )
    
    var folders = [Folder]()
    for url in contents {
      guard let folder = await fetchFolder(at: url)
      else { continue }
      folders.append(folder)
    }
    return folders
  }
  
  let root = "/Users/jessededa/Developement/Swift/03_Apps_TCA/ChefTime/ChefTime/Resources/JSON/"
  let f1 = await fetchFolders(root + "/system")
  let f2 = await fetchFolders(root + "/user")
  return f1 + f2
}

// TODO: Migrate your old data to the new data, including new dates!
// Fetches folder model from local JSON file. Assume directory is a user folder.
fileprivate func fetchFolder(at directoryURL: URL) async -> Folder? {
  guard let contents = try? FileManager.default.contentsOfDirectory(
    at: directoryURL,
    includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
    options: .skipsHiddenFiles
  )
  else { return nil }
  
  var folder = Folder(
    id: .init(),
    name: directoryURL.lastPathComponent, folderType: .user,
    creationDate: .init(),
    lastEditDate: .init()
  )
  for url in contents {
    if url.hasDirectoryPath {
      guard let childFolder = await fetchFolder(at: url)
      else { continue }
      
      if folder.imageData == nil {
        folder.imageData = childFolder.imageData
      }
      folder.folders.append(childFolder)
    }
    else if url.pathExtension.lowercased() == "json" {
      guard let recipe = await fetchRecipe(at: url)
      else { continue }
      folder.recipes.append(recipe)
      folder.name = folder.name.capitalized
      if folder.imageData == nil {
        folder.imageData = recipe.imageData.first
      }
    }
    else { continue }
  }
  if folder.name.lowercased() == "standard" {
    
  }
  folder.name = folder.name.capitalized
  if folder.imageData == nil {
    if let imageData = folder.recipes.first(where: { $0.imageData.first != nil })?.imageData.first {
      folder.imageData = imageData
    }
  }
  return folder
}

// Fetches recipe model from local JSON file.
fileprivate func fetchRecipe(at url: URL) async -> Recipe? {
  guard let data = try? Data(contentsOf: url),
        let recipeV0 = try? JSONDecoder().decode(RecipeV0.self, from: data)
  else { return nil }
  let recipe = Recipe.init(
    id: .init(rawValue: recipeV0.id.rawValue),
    name: recipeV0.name,
    imageData: recipeV0.imageData,
    aboutSections: recipeV0.aboutSections,
    ingredientSections: recipeV0.ingredientSections,
    stepSections: recipeV0.stepSections,
    creationDate: .init(),
    lastEditDate: .init()
  )
  return recipe
}

// Reads and writes recipe to disk given fileName and fileExtension.
fileprivate struct ReadWriteIO {
  let fileName: String
  let fileExtension: String
  
  var fileURL: URL {
    Bundle.main.url(forResource: fileName, withExtension: fileExtension)!
  }
  
  func writeRecipeToDisk(_ recipe: Recipe) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(recipe)
    try! data.write(to: fileURL, options: .atomic)
  }
  
  func readRecipeFromDisk() -> Recipe {
    let data = try! Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let recipe = try! decoder.decode(Recipe.self, from: data)
    return recipe
  }
}

import Tagged

struct RecipeV0: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var name: String = ""
  var imageData: IdentifiedArrayOf<ImageData> = []
  var aboutSections: IdentifiedArrayOf<Recipe.AboutSection> = []
  var ingredientSections: IdentifiedArrayOf<Recipe.IngredientSection> = []
  var stepSections: IdentifiedArrayOf<Recipe.StepSection> = []
  
  init(
    id: ID,
    name: String = "",
    imageData: IdentifiedArrayOf<ImageData> = [],
    aboutSections: IdentifiedArrayOf<Recipe.AboutSection> = [],
    ingredientSections: IdentifiedArrayOf<Recipe.IngredientSection> = [],
    stepSections: IdentifiedArrayOf<Recipe.StepSection> = []
  ) {
    self.id = id
    self.name = name
    self.imageData = imageData
    self.aboutSections = aboutSections
    self.ingredientSections = ingredientSections
    self.stepSections = stepSections
  }
}
