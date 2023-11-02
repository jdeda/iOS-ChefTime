import Tagged
import Foundation
import ComposableArchitecture
import SwiftData

/// Represents a recipe.
/// Recipes have a name and contain several lists of information describing what
/// the finished recipe looks like, any peritnent discussion about it, the ingredients, and steps.
@Model
final class SDRecipe: Identifiable, Equatable {
  
  @Attribute(.unique)
  let id: UUID
  
  var name: String = ""
  var imageData: [Data] = []
  
  @Relationship(deleteRule: .cascade, inverse: \SDAboutSection.parentRecipe)
  var aboutSections: [SDAboutSection] = []
  
  @Relationship(deleteRule: .cascade, inverse: \SDIngredientSection.parentRecipe)
  var ingredientSections: [SDIngredientSection] = []
  
  @Relationship(deleteRule: .cascade, inverse: \SDStepSection.parentRecipe)
  var stepSections: [SDStepSection] = []
  
  weak var parentFolder: SDFolder?
  
  init(
    id: UUID,
    name: String,
    imageData: [Data],
    aboutSections: [SDAboutSection],
    ingredientSections: [SDIngredientSection],
    stepSections: [SDStepSection],
    parentFolder: SDFolder? = nil
  ) {
    self.id = id
    self.name = name
    self.imageData = imageData
    self.aboutSections = aboutSections
    self.ingredientSections = ingredientSections
    self.stepSections = stepSections
    self.parentFolder = parentFolder
  }
  
  @Model
  final class SDAboutSection: Identifiable, Equatable {
    
    @Attribute(.unique)
    let id: UUID
    
    var name: String = ""
    var description_: String = ""
    
    weak var parentRecipe: SDRecipe?
    
    init(
      id: ID,
      name: String,
      description_: String,
      parentRecipe: SDRecipe? = nil
    ) {
      self.id = id
      self.name = name
      self.description_ = description_
      self.parentRecipe = parentRecipe
    }
  }
  
  @Model
  final class SDIngredientSection: Identifiable, Equatable {
    @Attribute(.unique)
    let id: UUID
    
    var name: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \SDIngredient.parentIngredientSection)
    var ingredients: [SDIngredient] = []
    
    weak var parentRecipe: SDRecipe?
    
    init(
      id: ID,
      name: String,
      ingredients: [SDIngredient],
      parentRecipe: SDRecipe? = nil
    ) {
      self.id = id
      self.name = name
      self.ingredients = ingredients
      self.parentRecipe = parentRecipe
    }
    
    @Model
    final class SDIngredient: Identifiable, Equatable {
      @Attribute(.unique)
      let id: UUID
      
      var name: String = ""
      var amount: Double = 0.0
      var measure: String = ""
      
      weak var parentIngredientSection: SDIngredientSection?
      
      init(
        id: UUID,
        name: String,
        amount: Double,
        measure: String,
        parentIngredientSection: SDIngredientSection? = nil
      ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.measure = measure
        self.parentIngredientSection = parentIngredientSection
      }
    }
  }
  
  @Model
  final class SDStepSection: Identifiable, Equatable {
    @Attribute(.unique)
    let id: UUID
    
    var name: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \SDStep.parentStepSection)
    var steps: [SDStep] = []
    
    weak var parentRecipe: SDRecipe?
    
    init(
      id: UUID,
      name: String,
      steps: [SDStep],
      parentRecipe: SDRecipe? = nil
    ) {
      self.id = id
      self.name = name
      self.steps = steps
      self.parentRecipe = parentRecipe
    }
    
    @Model
    final class SDStep: Identifiable, Equatable {
      @Attribute(.unique)
      let id: UUID
      
      var description_: String = ""
      var imageData: [Data] = []
      weak var parentStepSection: SDStepSection?
      
      init(
        id: UUID,
        description_: String,
        imageData: [Data],
        parentStepSection: SDStepSection? = nil
      ) {
        self.id = id
        self.description_ = description_
        self.imageData = imageData
        self.parentStepSection = parentStepSection
      }
    }
  }
}

