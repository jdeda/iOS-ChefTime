import Tagged
import Foundation
import ComposableArchitecture
import SwiftUI

struct CustomImageView: View {
  let imageData: Data?
  var body: some View {
    if let imageData, let uiImage = UIImage(data: imageData) {
      Image(uiImage: uiImage)
    }
    else {
      EmptyView()
    }
  }
}


struct Recipe: Identifiable, Equatable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var name: String
  var imageURL: URL?
  var about: String
  var ingredientSections: IdentifiedArrayOf<IngredientSection>
  var steps: IdentifiedArrayOf<StepSection>
  
  
  struct IngredientSection: Identifiable, Equatable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var ingredients: IdentifiedArrayOf<Ingredient>
    
    struct Ingredient: Identifiable, Equatable {
      typealias ID = Tagged<Self, UUID>
      
      let id: ID
      var name: String
      var amount: Double
      var measure: String
    }
  }
  
  struct StepSection: Identifiable, Equatable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var steps: IdentifiedArrayOf<Step>
    
    struct Step: Identifiable, Equatable {
      typealias ID = Tagged<Self, UUID>
      
      let id: ID
      var description: String
      var imageURL: URL?
    }
  }
}

extension Recipe {
  static let mock = Self.init(
    id: .init(),
    name: "Double Cheese Burger",
    imageURL: URL(string: "https://www.mcdonalds.com.mt/wp-content/uploads/2018/05/0005_WEBSITE-CHEESEBURGER.jpg")!,
    about: "A proper meat feast, this classical burger is just too good! Homemade buns and ground meat, served with your side of classic toppings, it makes a fantastic Friday night treat or cookout favorite.", ingredientSections: [
      .init(
        id: .init(),
        name: "Buns",
        ingredients: [
          .init(id: .init(), name: "Flour", amount: 2, measure: "cups"),
          .init(id: .init(), name: "Instant Yeast", amount: 2, measure: "tbsp"),
          .init(id: .init(), name: "Salt", amount: 2, measure: "tsp"),
          .init(id: .init(), name: "Sugar", amount: 2, measure: "tbsp"),
          .init(id: .init(), name: "Butter", amount: 2, measure: "stick"),
          .init(id: .init(), name: "Water", amount: 2, measure: "cups"),
        ]
      ),
      .init(
        id: .init(),
        name: "Patties",
        ingredients: [
          .init(id: .init(), name: "Beef Chuck", amount: 8, measure: "oz"),
          .init(id: .init(), name: "Beef Fat Trimmings or Beef Bone Marrow", amount: 2, measure: "oz")
        ]
      ),
      .init(
        id: .init(),
        name: "Toppings",
        ingredients: [
          .init(id: .init(), name: "Lettuce", amount: 2, measure: "leaves"),
          .init(id: .init(), name: "Tomato", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Onion", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Pickle", amount: 2, measure: "chips"),
          .init(id: .init(), name: "Ketchup", amount: 2, measure: "tbsp"),
          .init(id: .init(), name: "Mustard", amount: 2, measure: "tbsp")
        ]
      ),
    ],
    steps: [
      .init(id: .init(), name: "Buns", steps: [
        .init(
          id: .init(),
          description: "Combine ingredients into stand-mixer bowl and mix until incorporated, than allow mixer to knead for 10 minutes until taught and shiny.",
          imageURL: .init(string: "burger_bun_01")
        ),
        .init(
          id: .init(),
          description: "Once the dough is properly kneaded, place in bowl with a cover in a moderately warm area (70F-80F) and allow to rise for 2 hours or until at least doubled in size",
          imageURL: .init(string: "burger_bun_02")
        ),
        .init(
          id: .init(),
          description: "After dough has rised, pound the gas out and re-knead into a large ball, than roll out little dough balls by pressing and pinching. Cover your balls and let them rise for another hour or until they have at least doubled in size",
          imageURL: .init(string: "burger_bun_03")
        ),
        .init(
          id: .init(),
          description: "Once your balls have risen accordingly, uncover them and season with salt and semame seeds then bake at 450F for 45 minutes or until internal temp of 190F",
          imageURL: .init(string: "burger_bun_04")
        ),
        .init(
          id: .init(),
          description: "After baking, immediately remove from loaf pan and place on cooling rack to prevent dough steaming into itself and getting soggy. Baste your buns generously with butter and allow to them rest for 30 minutes before slicing",
          imageURL: .init(string: "burger_bun_05")
        ),
        .init(
          id: .init(),
          description: "Enjoy your beautiful creation!",
          imageURL: .init(string: "burger_bun_06")
        )
      ]),
      .init(id: .init(), name: "Patties", steps: [
        .init(id: .init(), description: "Roughly chop all meat into bite size pieces and pass through a meat grinder. It usually helps if the meat is very cold. Frozen meat is better than warm meat, but neither will give you the best result")
      ]),
      .init(id: .init(), name: "Toppings", steps: [
        .init(id: .init(), description: "Prepare the toppings as you like")
      ])
    ]
  )
}
