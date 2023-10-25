import Foundation
import SwiftData

// TODO: Handle image data...

// MARK: - SDModel --> Model
extension SDFolder {
  convenience init(_ folder: Folder) {
    self.init(
      id: folder.id.rawValue,
      name: folder.name,
      imageData: nil,
      folders: folder.folders.map(SDFolder.init),
      recipes: folder.recipes.map(SDRecipe.init),
      folderType: folder.folderType,
      parentFolder: nil
    )
  }
}

extension SDRecipe {
  convenience init(_ recipe: Recipe) {
    self.init(
      id: recipe.id.rawValue,
      name: recipe.name,
      imageData: [],
      aboutSections: recipe.aboutSections.elements.map(SDRecipe.SDAboutSection.init),
      ingredientSections: recipe.ingredientSections.elements.map(SDRecipe.SDIngredientSection.init),
      stepSections: recipe.stepSections.elements.map(SDRecipe.SDStepSection.init)
    )
  }
}

extension SDRecipe.SDAboutSection {
  convenience init(_ aboutSection: Recipe.AboutSection) {
    self.init(
      id: aboutSection.id.rawValue,
      name: aboutSection.name,
      description_: aboutSection.name.description
    )
  }
}

extension SDRecipe.SDIngredientSection {
  convenience init(_ ingredientSection: Recipe.IngredientSection) {
    self.init(
      id: ingredientSection.id.rawValue,
      name: ingredientSection.name,
      ingredients: ingredientSection.ingredients.elements.map(SDRecipe.SDIngredientSection.SDIngredient.init)
    )
  }
}

extension SDRecipe.SDIngredientSection.SDIngredient {
  convenience init(_ ingredient: Recipe.IngredientSection.Ingredient) {
    self.init(
      id: ingredient.id.rawValue,
      name: ingredient.name,
      amount: ingredient.amount,
      measure: ingredient.measure
    )
  }
}

extension SDRecipe.SDStepSection {
  convenience init(_ stepSection: Recipe.StepSection) {
    self.init(
      id: stepSection.id.rawValue,
      name: stepSection.name,
      steps: stepSection.steps.elements.map(SDRecipe.SDStepSection.SDStep.init)
    )
  }
}

extension SDRecipe.SDStepSection.SDStep {
  convenience init(_ step: Recipe.StepSection.Step) {
    self.init(
      id: step.id.rawValue,
      description_: step.description,
      imageData: []
    )
  }
}

// MARK: - Model --> SDModel
extension Folder {
  init(_ sdFolder: SDFolder) {
    self.init(
      id: .init(rawValue: sdFolder.id),
      name: sdFolder.name,
      imageData: nil,
      folders: .init(uniqueElements: sdFolder.folders.map(Folder.init)),
      recipes: .init(uniqueElements: sdFolder.recipes.map(Recipe.init)),
      folderType: sdFolder.folderType
    )
  }
}

extension Recipe {
  init(_ sdRecipe: SDRecipe) {
    self.init(
      id: .init(rawValue: sdRecipe.id),
      name: sdRecipe.name,
      imageData: [],
      aboutSections: .init(uniqueElements: sdRecipe.aboutSections.map(Recipe.AboutSection.init)),
      ingredientSections: .init(uniqueElements: sdRecipe.ingredientSections.map(Recipe.IngredientSection.init)),
      stepSections: .init(uniqueElements: sdRecipe.stepSections.map(Recipe.StepSection.init))
    )
  }
}


extension Recipe.AboutSection {
  init(_ sdAboutSection: SDRecipe.SDAboutSection) {
    self.init(
      id: .init(rawValue: sdAboutSection.id),
      name: sdAboutSection.name,
      description: sdAboutSection.description_
    )
  }
}

extension Recipe.IngredientSection {
  init(_ sdIngredientSection: SDRecipe.SDIngredientSection) {
    self.init(
      id: .init(rawValue: sdIngredientSection.id),
      name: sdIngredientSection.name,
      ingredients: .init(uniqueElements: sdIngredientSection.ingredients.map(Recipe.IngredientSection.Ingredient.init))
    )
  }
}

extension Recipe.IngredientSection.Ingredient {
  init(_ sdIngredient: SDRecipe.SDIngredientSection.SDIngredient) {
    self.init(
      id: .init(rawValue: sdIngredient.id),
      name: sdIngredient.name,
      amount: sdIngredient.amount,
      measure: sdIngredient.measure,
      isComplete: false
    )
  }
}

extension Recipe.StepSection {
  init(_ sdStepSection: SDRecipe.SDStepSection) {
    self.init(
      id: .init(rawValue: sdStepSection.id),
      name: sdStepSection.name,
      steps: .init(uniqueElements: sdStepSection.steps.map(Recipe.StepSection.Step.init))
    )
  }
}

extension Recipe.StepSection.Step {
  init(_ sdStep: SDRecipe.SDStepSection.SDStep) {
    self.init(
      id: .init(rawValue: sdStep.id),
      description: sdStep.description_,
      imageData: []
    )
  }
}
