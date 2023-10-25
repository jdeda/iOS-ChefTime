import Foundation
import ComposableArchitecture
import CoreData

extension Database {
  static let live = {
    let sdc = SDClient()! // TODO: Do not force unwrap
    return Self(
      retrieveRootFolders: {
        await sdc.retrieveRootFolders()
      },
      createFolder: { folder in
        try? await sdc.createFolder(folder)
      },
      retrieveFolder: { folderID in
        await sdc.retrieveFolder(folderID.rawValue)
      },
      updateFolder: { folder in
        try? await sdc.updateFolder(folder)
      },
      deleteFolder: { folder in
        try? await sdc.updateFolder(folder)
      },
      createRecipe: { recipe in
        try? await sdc.createRecipe(recipe)
      },
      retrieveRecipe: { recipeID in
        await sdc.retrieveRecipe(recipeID.rawValue)
      },
      updateRecipe: { recipe in
        try? await sdc.updateRecipe(recipe)
      },
      deleteRecipe: { recipe in
        try? await sdc.deleteRecipe(recipe)
      }
    )
  }()
}
