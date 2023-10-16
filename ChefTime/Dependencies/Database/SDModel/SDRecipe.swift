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
  
  @Relationship(deleteRule: .cascade)
  var aboutSections: [SDAboutSection] = []
  
  @Relationship(deleteRule: .cascade)
  var ingredientSections: [SDIngredientSection] = []
  
  @Relationship(deleteRule: .cascade)
  var stepSections: [SDStepSection] = []
  
  init(
    id: UUID,
    name: String,
    imageData: [Data],
    aboutSections: [SDAboutSection],
    ingredientSections: [SDIngredientSection],
    stepSections: [SDStepSection]
  ) {
    self.id = id
    self.name = name
    self.imageData = imageData
    self.aboutSections = aboutSections
    self.ingredientSections = ingredientSections
    self.stepSections = stepSections
  }
  
  @Model
  final class SDAboutSection: Identifiable, Equatable {
    
    @Attribute(.unique)
    let id: UUID
    
    var name: String = ""
    var description_: String = ""
    
    init(
      id: ID,
      name: String,
      description_: String
    ) {
      self.id = id
      self.name = name
      self.description_ = description_
    }
  }
  
  @Model
  final class SDIngredientSection: Identifiable, Equatable {
    @Attribute(.unique)
    let id: UUID
    
    var name: String = ""
    
    @Relationship(deleteRule: .cascade)
    var ingredients: [SDIngredient] = []
    
    init(
      id: ID,
      name: String,
      ingredients: [SDIngredient]
    ) {
      self.id = id
      self.name = name
      self.ingredients = ingredients
    }
    
    @Model
    final class SDIngredient: Identifiable, Equatable {
      @Attribute(.unique)
      let id: UUID
      
      var name: String = ""
      var amount: Double = 0.0
      var measure: String = ""
      var isComplete: Bool = false
      
      init(
        id: UUID,
        name: String,
        amount: Double,
        measure: String,
        isComplete: Bool
      ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.measure = measure
        self.isComplete = isComplete
      }
    }
  }
  
  @Model
  final class SDStepSection: Identifiable, Equatable {
    @Attribute(.unique)
    let id: UUID
    
    var name: String = ""
    
    @Relationship(deleteRule: .cascade)
    var steps: [SDStep] = []
    
    init(
      id: UUID,
      name: String,
      steps: [SDStep]
    ) {
      self.id = id
      self.name = name
      self.steps = steps
    }
    
    @Model
    final class SDStep: Identifiable, Equatable {
      @Attribute(.unique)
      let id: UUID
      
      var description_: String = ""
      var imageData: [Data] = []
      
      init(
        id: UUID,
        description_: String,
        imageData: [Data]
      ) {
        self.id = id
        self.description_ = description_
        self.imageData = imageData
      }
    }
  }
}
