import ComposableArchitecture
import Foundation

// MARK: - Temporary DB
struct Database {
  let fetchAllFolders: @Sendable () -> AsyncStream<Folder>
}

extension Database: DependencyKey {
  static let liveValue = Self.live
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue}
  }
}

extension Database {
  static let live = Self(
    fetchAllFolders: {
      .init { continuation in
        let task = Task {
          var rootURL = URL(string: "/Users/jessededa/Developement/Swift/03_Apps_TCA/ChefTime/ChefTime/Resources/JSON/user")!
          guard let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
            options: .skipsHiddenFiles
          )
          else {
            continuation.finish()
            return
          }
          
          for url in contents {
            guard let folder = await fetchFolder(at: url)
            else { continue }
            continuation.yield(folder)
          }
          
          continuation.finish()
        }
        continuation.onTermination = { _  in
          task.cancel()
        }
      }
    }
  )
}

// MARK: - ReadWriteIO
struct ReadWriteIO {
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

/// Assume directory is a user folder.
private func fetchFolder(at directoryURL: URL) async -> Folder? {
  guard let contents = try? FileManager.default.contentsOfDirectory(
    at: directoryURL,
    includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
    options: .skipsHiddenFiles
  )
  else { return nil }
  
  var folder = Folder(id: .init(), name: directoryURL.lastPathComponent, folderType: .user)
  for url in contents {
    if url.hasDirectoryPath {
      guard let childFolder = await fetchFolder(at: url)
      else { continue }
      folder.folders.append(childFolder)
    }
    else if url.pathExtension.lowercased() == "json" {
      guard let recipe = await fetchRecipe(at: url)
      else { continue }
      folder.recipes.append(recipe)
    }
    else {
      continue
    }
  }
  return folder
}

private func fetchRecipe(at url: URL) async -> Recipe? {
  guard let data = try? Data(contentsOf: url),
        let recipe = try? JSONDecoder().decode(Recipe.self, from: data)
  else { return nil }
  return recipe
}
