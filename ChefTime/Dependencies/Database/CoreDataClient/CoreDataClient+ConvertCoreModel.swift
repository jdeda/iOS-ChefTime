import Foundation
import CoreData

extension CoreUser {
  func toUser() -> User? {
    guard let id = self.id,
          let systemFoldersRaw = self.systemFolders as? Set<CoreFolder>,
          let userFoldersRaw = self.userFolders as? Set<CoreFolder>
    else { return nil }
    
    // MARK: - We are ignoring if it fails...
    let systemFolders: Array<Folder> = systemFoldersRaw.compactMap { $0.toFolder() }
    let userFolders: Array<Folder> = userFoldersRaw.compactMap { $0.toFolder() }
    
    return .init(
      id: .init(rawValue: id),
      systemFolders: .init(uniqueElements: systemFolders),
      userFolders: .init(uniqueElements: userFolders)
    )
  }
}

extension CoreFolder {
  func toFolder() -> Folder? {
    
    guard let id = self.id,
          let name = self.name,
          let foldersRaw = self.folders as? Set<CoreFolder>,
          let recipesRaw = self.recipes as? Set<CoreRecipe>,
          let folderType = self.folderType?.toFolderType()
    else { return nil }
    
    let folders: Array<Folder> = foldersRaw.compactMap { $0.toFolder() }
    let recipes: Array<Recipe> = recipesRaw.compactMap { $0.toRecipe() }
    
    return .init(
      id: .init(rawValue: id),
      name: name,
      imageData: nil, // MARK: - We only want to fetch on-demand UI
      folders: .init(uniqueElements: folders),
      recipes: .init(uniqueElements: recipes),
      folderType: folderType
    )
  }
}

private extension String {
  func toFolderType() -> Folder.FolderType? {
    for folderType in Folder.FolderType.allCases {
      if self.lowercased() == String(describing: folderType).lowercased() {
        return folderType
      }
    }
    return nil
  }
}

extension CoreRecipe {
  func toRecipe() -> Recipe? {
//    let aboutSectionsRaw = Array((self.aboutSections as? Set<CoreAboutSection>) ?? [])
//    let ingredientSectionsRaw = Array((self.ingredientSections as? Set<CoreIngredientSection>) ?? [])
//    let stepSectionsRaw = Array((self.stepSections as? Set<CoreStepSection>) ?? [])

    guard let id = self.id,
          let name = self.name,
          let aboutSectionsRaw = self.aboutSections as? Set<CoreAboutSection>,
          let ingredientSectionsRaw = self.ingredientSections as? Set<CoreIngredientSection>,
          let stepSectionsRaw = self.stepSections as? Set<CoreStepSection>
    else { return nil }
    
    let aboutSections: Array<Recipe.AboutSection> = aboutSectionsRaw.compactMap { $0.toAboutSection() }
    let ingredientSections: Array<Recipe.IngredientSection> = ingredientSectionsRaw.compactMap { $0.toIngredientSection() }
    let stepSections: Array<Recipe.StepSection> = stepSectionsRaw.compactMap { $0.toStepSection() }

    return Recipe(
      id: .init(rawValue: id),
      name: name,
      imageData: [], // MARK: - We only want to fetch on-demand UI
      aboutSections: .init(uniqueElements: aboutSections),
      ingredientSections: .init(uniqueElements: ingredientSections),
      stepSections: .init(uniqueElements: stepSections)
    )
  }
}

extension CoreAboutSection {
  func toAboutSection() -> Recipe.AboutSection? {
    guard let id = self.id,
          let name = self.name,
          let description = self.body
    else { return nil }
    return Recipe.AboutSection(
      id: .init(rawValue: id),
      name: name,
      description: description
    )
  }
}

extension CoreIngredientSection {
  func toIngredientSection() -> Recipe.IngredientSection? {
    guard let id = self.id,
          let name = self.name,
          let ingredientsRaw = self.ingredients as? Set<CoreIngredient>
    else { return nil }
    
    let ingredients: Array<Recipe.IngredientSection.Ingredient> = ingredientsRaw.compactMap { $0.toIngredient() }
    
    return Recipe.IngredientSection(
      id: .init(rawValue: id),
      name: name,
      ingredients: .init(uniqueElements: ingredients)
    )
  }
}

extension CoreIngredient {
  func toIngredient() -> Recipe.IngredientSection.Ingredient? {
    guard let id = self.id,
          let name = self.name,
          let measure = self.measure
    else { return nil }
    
    let amount = self.amount < 0.0 ? 0.0 : self.amount
    
    return Recipe.IngredientSection.Ingredient(
      id: .init(rawValue: id),
      name: name,
      amount: amount,
      measure: measure,
      isComplete: false
    )
  }
}

extension CoreStepSection {
  func toStepSection() -> Recipe.StepSection? {
    guard let id = self.id,
          let name = self.name,
          let stepsRaw = self.steps as? Set<CoreStep>
    else { return nil }
    
    let steps: Array<Recipe.StepSection.Step> = stepsRaw.compactMap { $0.toStep() }
    
    return Recipe.StepSection(
      id: .init(rawValue: id),
      name: name,
      steps: .init(uniqueElements: steps)
    )
  }
}

extension CoreStep {
  func toStep() -> Recipe.StepSection.Step? {
    guard let id = self.id,
          let description = self.body
    else { return nil }
    
    return Recipe.StepSection.Step(
      id: .init(rawValue: id),
      description: description,
      imageData: [] // MARK: - We only want to fetch on-demand UI
    )
  }
}
