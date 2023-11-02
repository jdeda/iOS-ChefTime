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
        return await sdc.retrieveFolder(folderID)
      },
      updateFolder: { folder in
        try? await sdc.updateFolder(folder)
      },
      deleteFolder: { folderID in
        try? await sdc.deleteFolder(folderID)
      },
      createRecipe: { recipe in
        try? await sdc.createRecipe(recipe)
      },
      retrieveRecipe: { recipeID in
        await sdc.retrieveRecipe(recipeID)
      },
      updateRecipe: { recipe in
        try? await sdc.updateRecipe(recipe)
      },
      deleteRecipe: { recipeID in
        try? await sdc.deleteRecipe(recipeID)
      }
    )
  }()
}
