import Foundation
import CoreData

// TODO: What about parent connections?????


/// CoreDataType -> SwiftType
/// 1. Unwrap every value
/// 2. Cast every value

/// SwiftType -> CoreDataType
/// 1. Pass a mutable context
/// 2. Create and unwrap an entity
/// 3. Init everything with transforms and make sure your types are matching because of stupid NSSet
/// 4. Link relations
///
/// Common Problems
/// 1. must make sure you init everything, compiler doesn't help you at all
/// 2. if u put rules that make values non-optional, the compiler doesn't help you at all, putting nil with crash i think
///
extension User {
  func toCoreUser(_ context: NSManagedObjectContext) -> CoreUser? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreUser", in: context)
    else { return nil }
    let coreUser = CoreUser(entity: entity, insertInto: context)
    coreUser.id = self.id.rawValue
    coreUser.systemFolders = .init(array: self.systemFolders.compactMap { $0.toCoreFolder(context) })
    coreUser.userFolders = .init(array: self.userFolders.compactMap { $0.toCoreFolder(context) })
    return nil
  }
}

extension Folder {
  func toCoreFolder(_ context: NSManagedObjectContext) -> CoreFolder? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreFolder", in: context)
    else { return nil }
    let coreFolder = CoreFolder(entity: entity, insertInto: context)
    coreFolder.id = self.id.rawValue
    coreFolder.name = self.name
    coreFolder.imageData = nil // MARK: - Special persistence for images...
    coreFolder.folderType = self.folderType.toFolderString()
    coreFolder.folders = .init(array: self.folders.compactMap({ $0.toCoreFolder(context) }))
    coreFolder.recipes = .init(array: self.recipes.compactMap( { $0.toCoreRecipe} ))
    return coreFolder
  }
}

private extension Folder.FolderType {
  func toFolderString() -> String {
    switch self {
    case .systemAll: return "systemAll"
    case .systemStandard: return "systemStandard"
    case .systemRecentlyDeleted: return "systemRecentlyDeleted"
    case .user: return "user"
    }
  }
}

extension Recipe {
  func toCoreRecipe(_ context: NSManagedObjectContext) -> CoreRecipe? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreRecipe", in: context)
    else { return nil }
    let coreRecipe = CoreRecipe(entity: entity, insertInto: context)
    coreRecipe.id = self.id.rawValue
    coreRecipe.name = self.name
    coreRecipe.imageData = [] // MARK: - Special persistence for images...
    coreRecipe.aboutSections = .init(array: self.aboutSections.compactMap { $0.toCoreAboutSection(context) })
    coreRecipe.ingredientSections = .init(array: self.ingredientSections.compactMap { $0.toCoreIngredientSection(context) })
    coreRecipe.stepSections = .init(array: self.stepSections.compactMap { $0.toCoreStepSection(context) })
    return coreRecipe
  }
}

extension Recipe.AboutSection {
  func toCoreAboutSection(_ context: NSManagedObjectContext) -> CoreAboutSection? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreAboutSection", in: context)
    else { return nil }
    let coreAboutSection = CoreAboutSection(entity: entity, insertInto: context)
    coreAboutSection.id = self.id.rawValue
    coreAboutSection.name = self.name
    coreAboutSection.body = self.description
    return coreAboutSection
  }
}

extension Recipe.IngredientSection {
  func toCoreIngredientSection(_ context: NSManagedObjectContext) -> CoreIngredientSection? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreIngredientSection", in: context)
    else { return nil }
    let coreIngredientSection = CoreIngredientSection(entity: entity, insertInto: context)
    coreIngredientSection.id = self.id.rawValue
    coreIngredientSection.name = self.name
    coreIngredientSection.ingredients = .init(array: self.ingredients.compactMap { $0.toCoreIngredient(context) })
    return coreIngredientSection
  }
}

extension Recipe.IngredientSection.Ingredient {
  func toCoreIngredient(_ context: NSManagedObjectContext) -> CoreIngredient? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreIngredient", in: context)
    else { return nil }
    let coreIngredient = CoreIngredient(entity: entity, insertInto: context)
    coreIngredient.id = self.id.rawValue
    coreIngredient.name = self.name
    coreIngredient.amount = self.amount
    coreIngredient.measure = self.measure
    return coreIngredient
  }
}

extension Recipe.StepSection {
  func toCoreStepSection(_ context: NSManagedObjectContext) -> CoreStepSection? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreStepSection", in: context)
    else { return nil }
    let coreStepSection = CoreStepSection(entity: entity, insertInto: context)
    coreStepSection.id = self.id.rawValue
    coreStepSection.name = self.name
    coreStepSection.steps = .init(array: self.steps.compactMap { $0.toCoreStep(context) })
    return coreStepSection
  }
}

extension Recipe.StepSection.Step {
  func toCoreStep(_ context: NSManagedObjectContext) -> CoreStep? {
    guard let entity = NSEntityDescription.entity(forEntityName: "CoreStep", in: context)
    else { return nil }
    let coreStep = CoreStep(entity: entity, insertInto: context)
    coreStep.id = self.id.rawValue
    coreStep.body = self.description
    coreStep.imageData = [] // MARK: - Special persistence for images...
    return coreStep
  }
}
