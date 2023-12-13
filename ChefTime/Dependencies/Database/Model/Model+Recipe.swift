import Tagged
import Foundation
import ComposableArchitecture
import SwiftData

// MARK: - SDModel
/// Represents a recipe.
/// Recipes have a name and contain several lists of information describing what
/// the finished recipe looks like, any peritnent discussion about it, the ingredients, and steps.
@Model
final class SDRecipe: Identifiable, Equatable {
  let id: UUID
  
  var name: String = ""
  
  @Attribute(.externalStorage)
  var imageData: [SDData] = []

  @Relationship(deleteRule: .cascade, inverse: \SDAboutSection.parentRecipe)
  var aboutSections: [SDAboutSection] = []
  
  @Relationship(deleteRule: .cascade, inverse: \SDIngredientSection.parentRecipe)
  var ingredientSections: [SDIngredientSection] = []
  
  @Relationship(deleteRule: .cascade, inverse: \SDStepSection.parentRecipe)
  var stepSections: [SDStepSection] = []
  
  weak var parentFolder: SDFolder?
  
  let creationDate: Date
  
  var lastEditDate: Date
  
  var searchString: String
  
  init(
    id: UUID,
    name: String,
    imageData: [SDData],
    aboutSections: [SDAboutSection],
    ingredientSections: [SDIngredientSection],
    stepSections: [SDStepSection],
    parentFolder: SDFolder? = nil,
    creationDate: Date,
    lastEditDate: Date,
    searchString: String
  ) {
    self.id = id
    self.name = name
    self.imageData = imageData
    self.aboutSections = aboutSections
    self.ingredientSections = ingredientSections
    self.stepSections = stepSections
    self.parentFolder = parentFolder
    self.creationDate = creationDate
    self.lastEditDate = lastEditDate
    self.searchString = searchString
  }
  
  convenience init(_ recipe: Recipe) {
    self.init(
      id: recipe.id.rawValue,
      name: recipe.name,
      imageData: recipe.imageData.enumerated().map({SDData($0.element, $0.offset)}),
      aboutSections: recipe.aboutSections.enumerated().map({SDRecipe.SDAboutSection($0.element, $0.offset)}),
      ingredientSections: recipe.ingredientSections.enumerated().map({SDRecipe.SDIngredientSection($0.element, $0.offset)}),
      stepSections: recipe.stepSections.enumerated().map({SDRecipe.SDStepSection($0.element, $0.offset)}),
      creationDate: recipe.creationDate,
      lastEditDate: recipe.lastEditDate,
      searchString: [ // TODO: This is bad and needs to be replaced
        recipe.name,
        recipe.aboutSections.reduce("", { $0 + " " + $1.name + " " + $1.description }),
        recipe.ingredientSections.reduce("", { $0 + " " + $1.name + " " + $1.ingredients.map(\.name).joined(separator: " ") }),
        recipe.stepSections.reduce("", { $0 + " " + $1.name + " " + $1.steps.map(\.description).joined(separator: " ") }),
      ]
        .joined(separator: " ")
        .lowercased()
    )
  }
  // UPDATE PROTOCOL
  func updateFromValueType(_ value: Recipe) {
    self.name = value.name
    // self.imageData.updateFromValueType(value.imageData)
  }

  @Model
  final class SDAboutSection: Identifiable, Equatable {
    let id: UUID
    
    var name: String = ""
    var description_: String = ""
    
    weak var parentRecipe: SDRecipe?
    
    var positionPriority: Int?
    
    init(
      id: ID,
      name: String,
      description_: String,
      parentRecipe: SDRecipe? = nil,
      positionPriority: Int? = nil
    ) {
      self.id = id
      self.name = name
      self.description_ = description_
      self.parentRecipe = parentRecipe
      self.positionPriority = positionPriority
    }
    
    convenience init(_ aboutSection: Recipe.AboutSection, _ positionPriority: Int? = nil) {
      self.init(
        id: aboutSection.id.rawValue,
        name: aboutSection.name,
        description_: aboutSection.description,
        positionPriority: positionPriority
      )
    }
  }
  
  @Model
  final class SDIngredientSection: Identifiable, Equatable {
    let id: UUID
  
    var name: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \SDIngredient.parentIngredientSection)
    var ingredients: [SDIngredient] = []
    
    weak var parentRecipe: SDRecipe?
    
    var positionPriority: Int?
    
    init(
      id: ID,
      name: String,
      ingredients: [SDIngredient],
      parentRecipe: SDRecipe? = nil,
      positionPriority: Int? = nil
    ) {
      self.id = id
      self.name = name
      self.ingredients = ingredients
      self.parentRecipe = parentRecipe
      self.positionPriority = positionPriority
    }
    
    convenience init(_ ingredientSection: Recipe.IngredientSection, _ positionPriority: Int? = nil) {
      self.init(
        id: ingredientSection.id.rawValue,
        name: ingredientSection.name,
        ingredients: ingredientSection.ingredients.enumerated().map({SDRecipe.SDIngredientSection.SDIngredient($0.element, $0.offset)}),
        positionPriority: positionPriority
      )
    }
    
    @Model
    final class SDIngredient: Identifiable, Equatable {
      let id: UUID
      var name: String = ""
      var amount: Double = 0.0
      var measure: String = ""
      weak var parentIngredientSection: SDIngredientSection?
      var positionPriority: Int?
      
      init(
        id: UUID,
        name: String,
        amount: Double,
        measure: String,
        parentIngredientSection: SDIngredientSection? = nil,
        positionPriority: Int? = nil
      ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.measure = measure
        self.parentIngredientSection = parentIngredientSection
        self.positionPriority = positionPriority
      }
      
      convenience init(_ ingredient: Recipe.IngredientSection.Ingredient, _ positionPriority: Int? = nil) {
        self.init(
          id: ingredient.id.rawValue,
          name: ingredient.name,
          amount: ingredient.amount,
          measure: ingredient.measure,
          positionPriority: positionPriority
        )
      }
    }
  }
  
  @Model
  final class SDStepSection: Identifiable, Equatable {
    let id: UUID
    
    var name: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \SDStep.parentStepSection)
    var steps: [SDStep] = []
    
    weak var parentRecipe: SDRecipe?
    
    var positionPriority: Int?
    
    init(
      id: UUID,
      name: String,
      steps: [SDStep],
      parentRecipe: SDRecipe? = nil,
      positionPriority: Int? = nil
    ) {
      self.id = id
      self.name = name
      self.steps = steps
      self.parentRecipe = parentRecipe
      self.positionPriority = positionPriority
    }
    
    convenience init(_ stepSection: Recipe.StepSection, _ positionPriority: Int? = nil) {
      self.init(
        id: stepSection.id.rawValue,
        name: stepSection.name,
        steps: stepSection.steps.enumerated().map({SDRecipe.SDStepSection.SDStep($0.element, $0.offset)}),
        positionPriority: positionPriority
      )
    }
    
    @Model
    final class SDStep: Identifiable, Equatable {
      let id: UUID
      
      var description_: String = ""
      
      @Attribute(.externalStorage)
      var imageData: [SDData] = []

      weak var parentStepSection: SDStepSection?
      
      var positionPriority: Int?
      
      init(
        id: UUID,
        description_: String,
        imageData: [SDData],
        parentStepSection: SDStepSection? = nil,
        positionPriority: Int? = nil
      ) {
        self.id = id
        self.description_ = description_
        self.imageData = imageData
        self.parentStepSection = parentStepSection
        self.positionPriority = positionPriority
      }
      
      convenience init(_ step: Recipe.StepSection.Step, _ positionPriority: Int? = nil) {
        self.init(
          id: step.id.rawValue,
          description_: step.description,
          imageData: step.imageData.enumerated().map({SDData($0.element, $0.offset)}),
          positionPriority: positionPriority
        )
      }
    }
  }
}

// MARK: - Model
/// Represents a recipe.
/// Recipes have a name and contain several lists of information describing what
/// the finished recipe looks like, any peritnent discussion about it, the ingredients, and steps.
struct Recipe: Identifiable, Equatable, Codable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var parentFolderID: Folder.ID?
  var name: String = ""
  var imageData: IdentifiedArrayOf<ImageData> = []
  var aboutSections: IdentifiedArrayOf<AboutSection> = []
  var ingredientSections: IdentifiedArrayOf<IngredientSection> = []
  var stepSections: IdentifiedArrayOf<StepSection> = []
  let creationDate: Date
  var lastEditDate: Date
  
  init(
    id: ID,
    parentFolderID: Folder.ID? = nil,
    name: String = "",
    imageData: IdentifiedArrayOf<ImageData> = [],
    aboutSections: IdentifiedArrayOf<AboutSection> = [],
    ingredientSections: IdentifiedArrayOf<IngredientSection> = [],
    stepSections: IdentifiedArrayOf<StepSection> = [],
    creationDate: Date,
    lastEditDate: Date
  ) {
    self.id = id
    self.parentFolderID = parentFolderID
    self.name = name
    self.imageData = imageData
    self.aboutSections = aboutSections
    self.ingredientSections = ingredientSections
    self.stepSections = stepSections
    self.creationDate = creationDate
    self.lastEditDate = lastEditDate
  }
  
  // TODO: This probably needs proper ordering...
  init(_ sdRecipe: SDRecipe) {
    let _id: UUID? = sdRecipe.parentFolder?.id
    self.init(
      id: .init(rawValue: sdRecipe.id),
      parentFolderID: _id.flatMap({.init(rawValue: $0)}) ?? nil,
      name: sdRecipe.name,
      imageData: .init(uniqueElements: sdRecipe.imageData.sorted(using: KeyPathComparator(\.positionPriority)).compactMap(ImageData.init)),
      aboutSections: .init(uniqueElements: sdRecipe.aboutSections.sorted(using: KeyPathComparator(\.positionPriority)).map(Recipe.AboutSection.init)),
      ingredientSections: .init(uniqueElements: sdRecipe.ingredientSections.sorted(using: KeyPathComparator(\.positionPriority)).map(Recipe.IngredientSection.init)),
      stepSections: .init(uniqueElements: sdRecipe.stepSections.sorted(using: KeyPathComparator(\.positionPriority)).map(Recipe.StepSection.init)),
      creationDate: sdRecipe.creationDate,
      lastEditDate: sdRecipe.lastEditDate
    )
  }
  
  struct AboutSection: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var description: String = ""
    
    init(
      id: ID,
      name: String = "",
      description: String = ""
    ) {
      self.id = id
      self.name = name
      self.description = description
    }
    
    init(_ sdAboutSection: SDRecipe.SDAboutSection) {
      self.init(
        id: .init(rawValue: sdAboutSection.id),
        name: sdAboutSection.name,
        description: sdAboutSection.description_
      )
    }
  }
  
  struct IngredientSection: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var ingredients: IdentifiedArrayOf<Ingredient> = []
    
    init(
      id: ID,
      name: String = "",
      ingredients: IdentifiedArrayOf<Ingredient> = []
    ) {
      self.id = id
      self.name = name
      self.ingredients = ingredients
    }
    
    init(_ sdIngredientSection: SDRecipe.SDIngredientSection) {
      self.init(
        id: .init(rawValue: sdIngredientSection.id),
        name: sdIngredientSection.name,
        ingredients: .init(uniqueElements: sdIngredientSection.ingredients.sorted(using: KeyPathComparator(\.positionPriority)).map(Recipe.IngredientSection.Ingredient.init))
      )
    }
    
    struct Ingredient: Identifiable, Equatable, Codable {
      typealias ID = Tagged<Self, UUID>
      
      let id: ID
      var name: String = ""
      var amount: Double = 0.0
      var measure: String = ""
      
      init(
        id: ID,
        name: String = "",
        amount: Double = 0.0,
        measure: String = ""
      ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.measure = measure
      }
      
      init(_ sdIngredient: SDRecipe.SDIngredientSection.SDIngredient) {
        self.init(
          id: .init(rawValue: sdIngredient.id),
          name: sdIngredient.name,
          amount: sdIngredient.amount,
          measure: sdIngredient.measure
        )
      }
    }
  }
  
  struct StepSection: Identifiable, Equatable, Codable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String = ""
    var steps: IdentifiedArrayOf<Step> = []
    
    init(
      id: ID,
      name: String = "",
      steps: IdentifiedArrayOf<Step> = []
    ) {
      self.id = id
      self.name = name
      self.steps = steps
    }
    
    init(_ sdStepSection: SDRecipe.SDStepSection) {
      self.init(
        id: .init(rawValue: sdStepSection.id),
        name: sdStepSection.name,
        steps: .init(uniqueElements: sdStepSection.steps.sorted(using: KeyPathComparator(\.positionPriority)).map(Recipe.StepSection.Step.init))
      )
    }
    
    struct Step: Identifiable, Equatable, Codable {
      typealias ID = Tagged<Self, UUID>
      
      let id: ID
      var description: String = ""
      var imageData: IdentifiedArrayOf<ImageData> = []
      
      init(
        id: ID,
        description: String = "",
        imageData: IdentifiedArrayOf<ImageData> = []
      ) {
        self.id = id
        self.description = description
        self.imageData = imageData
      }
      
      init(_ sdStep: SDRecipe.SDStepSection.SDStep) {
        self.init(
          id: .init(rawValue: sdStep.id),
          description: sdStep.description_,
          imageData: .init(uniqueElements: sdStep.imageData.sorted(using: KeyPathComparator(\.positionPriority)).compactMap(ImageData.init))
        )
      }
    }
  }
}

// MARK: - EmptyMock
extension Recipe {
  static let empty = Self(id: .init(), creationDate: .init(), lastEditDate: .init())
}

// MARK: - ShortMock
extension Recipe {
  static let shortMock = Recipe.init(
    id: .init(),
    name: "Double Cheese Burger",
    imageData: [
      .init(
        id: .init(),
        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_00", withExtension: "jpeg")!))!
      )!
    ],
    aboutSections: [
      .init(
        id: .init(),
        name: "Description",
        description: "A proper meat feast, this classical burger is just too good! Homemade buns and ground meat, served with your side of classic toppings, it makes a fantastic Friday night treat or cookout favorite."
      )
    ],
    ingredientSections: [
      .init(
        id: .init(),
        name: "Burger",
        ingredients: [
          .init(id: .init(), name: "Buns", amount: 1, measure: "store pack"),
          .init(id: .init(), name: "Frozen Beef Patties", amount: 1, measure: "lb"),
          .init(id: .init(), name: "Lettuce", amount: 2, measure: "leaves"),
          .init(id: .init(), name: "Tomato", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Onion", amount: 2, measure: "thick slices"),
          .init(id: .init(), name: "Pickle", amount: 2, measure: "chips"),
          .init(id: .init(), name: "Ketchup", amount: 2, measure: "tbsp"),
          .init(id: .init(), name: "Mustard", amount: 2, measure: "tbsp")
        ]
      ),
    ],
    stepSections: [
      .init(id: .init(), name: "Burger", steps: [
        .init(
          id: .init(),
          description: "Toast the buns"
        ),
        .init(
          id: .init(),
          description: "Fry the burger patties"
        ),
        .init(
          id: .init(),
          description: "Assemble with toppings to your liking"
        ),
      ])
    ],
    creationDate: .init(),
    lastEditDate: .init()
  )
}

// MARK: - Long Mock
// TODO: There are a LOT of force unwraps...
// TODO: Put all of these into a JSON file then load them...
extension Recipe {
  static let longMock = Recipe(
    id: .init(),
    name: "Double Cheese Burger",
    imageData: [
      .init(
        id: .init(),
        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_00", withExtension: "jpeg")!))!
      )!,
      .init(
        id: .init(),
        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_01", withExtension: "jpeg")!))!
      )!,
      .init(
        id: .init(),
        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_02", withExtension: "jpeg")!))!
      )!,
    ],
    aboutSections: [
      .init(
        id: .init(),
        name: "Description",
        description: "A proper meat feast, this classical burger is just too good! Homemade buns and ground meat, served with your side of classic toppings, it makes a fantastic Friday night treat or cookout favorite."
      ),
      .init(
        id: .init(),
        name: "Do I Really Need To Make Homemade Bread?",
        description: "Of course not, there are great products in the store. But what's the fun in that?"
      ),
      .init(
        id: .init(),
        name: "Possible Improvements",
        description: "I think burgers need sweet toppings. I think some bacon onion jam, bbq sauce, and even fried onions would make this burger over the top good. Chargrilling these burgers will also make a world of difference. If you can't do that, than a smash patty is the best alternative. Make sure the pan is super ultra mega hot first!"
      ),
    ],
    ingredientSections: [
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
      )
    ],
    stepSections: [
      .init(id: .init(), name: "Buns", steps: [
        .init(
          id: .init(),
          description: "Combine ingredients into stand-mixer bowl and mix until incorporated, than allow mixer to knead for 10 minutes until taught and shiny.",
          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_01", withExtension: "jpg")!))!)! ]
        ),
        .init(
          id: .init(),
          description: "Once the dough is properly kneaded, place in bowl with a cover in a moderately warm area (70F-80F) and allow to rise for 2 hours or until at least doubled in size",
          
          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_02", withExtension: "jpg")!))!)! ]
        ),
        .init(
          id: .init(),
          description: "After dough has rised, pound the gas out and re-knead into a large ball, than roll out little dough balls by pressing and pinching. Cover your balls and let them rise for another hour or until they have at least doubled in size",
          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_03", withExtension: "jpg")!))!)! ]
        ),
        .init(
          id: .init(),
          description: "Once your balls have risen accordingly, uncover them and season with salt and semame seeds then bake at 450F for 45 minutes or until internal temp of 190F",
          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_04", withExtension: "jpg")!))!)! ]
        ),
        .init(
          id: .init(),
          description: "After baking, immediately remove from loaf pan and place on cooling rack to prevent dough steaming into itself and getting soggy. Baste your buns generously with butter and allow to them rest for 30 minutes before slicing",
          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_05", withExtension: "jpg")!))!)! ]
        ),
        .init(
          id: .init(),
          description: "Enjoy your beautiful creation!",
          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_06", withExtension: "jpg")!))!)! ]
        )
      ]),
      .init(id: .init(), name: "Patties", steps: [
        .init(
          id: .init(),
          description: "Roughly chop all meat into bite size pieces and pass through a meat grinder. It usually helps if the meat is very cold, if not frozen. Then form into patties. Work the meat if needed just enough for the meat to be able to form patties easily.",
          imageData: [
            .init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_meat_01", withExtension: "jpg")!))!)!,
            .init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_meat_02", withExtension: "jpg")!))!)!,
            .init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_meat_03", withExtension: "jpg")!))!)!,
            .init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_meat_04", withExtension: "jpg")!))!)!,
            
          ]
        )
      ]),
      .init(id: .init(), name: "Toppings", steps: [
        .init(id: .init(), description: "Prepare the toppings as you like")
      ])
    ],
    creationDate: .init(),
    lastEditDate: .init()
  )
}
