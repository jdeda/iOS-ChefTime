import Tagged
import Foundation
import ComposableArchitecture
import SwiftUI

struct Recipe: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var name: String = ""
  var imageData: IdentifiedArrayOf<ImageData> = []
  var aboutSections: IdentifiedArrayOf<AboutSection> = []
  var ingredientSections: IdentifiedArrayOf<IngredientSection> = []
  var stepSections: IdentifiedArrayOf<StepSection> = []
  
  struct AboutSection: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var description: String = ""
  }
  
  struct IngredientSection: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var ingredients: IdentifiedArrayOf<Ingredient> = []
    
    struct Ingredient: Identifiable, Equatable, Codable {
      typealias ID = Tagged<Self, UUID>
      
      let id: ID
      var name: String = ""
      var amount: Double = 0.0
      var measure: String = ""
      var isComplete: Bool = false
    }
  }
  
  struct StepSection: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var steps: IdentifiedArrayOf<Step> = []
    
    struct Step: Identifiable, Equatable, Codable {
      typealias ID = Tagged<Self, UUID>
      
      let id: ID
      var description: String = ""
      var imageData: IdentifiedArrayOf<ImageData> = []
    }
  }
}

// There are a LOT of force unwraps...
// TODO: Put all of these into a JSON file then load them...
extension Recipe {
  static let empty = Self(id: .init())
}
