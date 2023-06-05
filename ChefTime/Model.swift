import Tagged

struct RecipeZ {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var name: String
  var imageURL: URL?
  var ingredients: [Ingredients]
  var steps: [Step]
  var notes: String
  
  
  struct Ingredients {
    let name: String
    let ingredients: [Ingredient]
    
    struct Ingredient {
      let name: String
      let amount: Double
      let measure: String
    }
  }
  
  struct Step {
    let name: String
    let steps: [String]
  }
}

extension RecipeZ {
  static let mock = Self.init(
    id: .init(),
    name: "Double Cheese Burger",
    imageURL: URL(string: "https://www.mcdonalds.com.mt/wp-content/uploads/2018/05/0005_WEBSITE-CHEESEBURGER.jpg")!,
    ingredients: [
      .init(
        name: "Buns",
        ingredients: [
          .init(name: "Flour", amount: 2, measure: "cups"),
          .init(name: "Instant Yeast", amount: 2, measure: "tbsp"),
          .init(name: "Salt", amount: 2, measure: "tsp"),
          .init(name: "Sugar", amount: 2, measure: "tbsp"),
          .init(name: "Butter", amount: 2, measure: "stick"),
          .init(name: "Water", amount: 2, measure: "cups"),
        ]
      ),
      .init(
        name: "Patties",
        ingredients: [
          .init(name: "Beef Chuck", amount: 8, measure: "oz"),
          .init(name: "Beef Fat Trimmings or Beef Bone Marrow", amount: 2, measure: "oz")
        ]
      ),
      .init(
        name: "Toppings",
        ingredients: [
          .init(name: "Lettuce", amount: 2, measure: "leaves"),
          .init(name: "Tomato", amount: 2, measure: "thick slices"),
          .init(name: "Onion", amount: 2, measure: "thick slices"),
          .init(name: "Pickle", amount: 2, measure: "chips"),
          .init(name: "Ketchup", amount: 2, measure: "tbsp"),
          .init(name: "Mustard", amount: 2, measure: "tbsp")
        ]
      ),
    ],
    steps: [
      .init(name: "Buns", steps: [
        "Combine ingredients into stand-mixer bowl and mix until incorporated, than allow mixer to knead for 10 minutes until taught and shiny.",
        "Once the dough is properly kneaded, place in bowl with a cover in a moderately warm area (70F-80F) and allow to rise for 2 hours or until at least doubled in size",
        "After dough has rised, pound the gas out and re-knead into a large ball, than roll out little dough balls by pressing and pinching. Cover your balls and let them rise for another hour or until they have at least doubled in size",
        "Bake at 450F for 45 minutes or until internal temp of 190F",
        "After baking, immediately remove from loaf pan and place on cooling rack to prevent dough steaming into itself and getting soggy. Allow to rest for 30 minutes before slicing"
      ]),
      .init(name: "Patties", steps: [
        "Combine the beef and fat in a meat grinder with a coarse grind",
        "Press freshly ground meat into 1/3 pound patties. Work the meat as little as you can -- the more you knead it, the tougher it will become. Do not season until you are about to cook them. This is because certain additives such as citrus, garlic, or especially ginger will breakdown the meat leaving a slimy texture.",
        "Get a thick cast iron skillet extremely hot (450F-500F). Add a patty and smash it paper thin. The extreme heat will instantly crispen the burger, almost into a chip. This is a smash burger. Immediately season and continue cooking until surface is a pale gray,",
        "Once surface is pale gray, flip, top the patties with slices of cheese, add a splash of water into the pan, add a lid and cook for 30 seconds. The cheesee will steam and the burger will be completely cooked.",
        "Prepare for assembly!"
        
      ]),
      .init(name: "Toppings", steps: [
        "Choose your toppings as you like and assemble as you like!"
      ])
    ],
    notes: "A proper meat feast, this classical burger is just too good! Homemade buns and ground meat, served with your side of classic toppings, it makes a fantastic Friday night treat or cookout favorite."
  )
}

struct Step {
  let name: String
  let steps: [(String, String)]
}

let mockSteps: [Step] = [
  .init(name: "Buns", steps: [
    (
      "burger_bun_01",
      "Combine dry ingredients in a large bowl and mix throughly"
    ),
    (
      "burger_bun_02",
      "Add butter to dry mixture and incorporate thoroughly. The butter should be almost completely emulsified into the dry ingredients. There should be no clumps. "
    ),
    (
      "burger_bun_03",
      "Slowy add warm water (about 100F) to your mixture and mix until a large batter forms. The dough should barely stick to your fingers, add flour if the dough is too sticky. "
    ),
    (
      "burger_bun_04",
      "Vigoruously knead the dough for 10 minutes until the surface is shiny, taught, and doesn't stick at all. As you knead, the dough will transform into these characteristics."
    ),
    (
      "burger_bun_05",
      "Once the dough is properly kneaded, place in bowl with a cover in a moderately warm area (70F-80F) and allow to rise for 2 hours or until at least doubled in size"
    ),
    (
      "burger_bun_06",
      "After dough has rised, pound the gas out and re-knead into a large ball, than roll out little dough balls by pressing and pinching. Cover your balls and let them rise for another hour or until they have at least doubled in size"
    ),
    (
      "Foo",
      "Bake at 450F for 45 minutes or until internal temp of 190F"
    ),
    (
      "Foo",
      "After baking, immediately remove from loaf pan and place on cooling rack to prevent dough steaming into itself and getting soggy. Allow to rest for 30 minutes before slicing"
    )
  ]),
  .init(name: "Patties", steps: [
    (
      "Foo",
      "Combine the beef and fat in a meat grinder with a coarse grind"
    ),
    (
      "Foo",
      "Press freshly ground meat into 1/3 pound patties. Work the meat as little as you can -- the more you knead it, the tougher it will become. Do not season until you are about to cook them. This is because certain additives such as citrus, garlic, or especially ginger will breakdown the meat leaving a slimy texture."
    ),
    (
      "Foo",
      "Get a thick cast iron skillet extremely hot (450F-500F). Add a patty and smash it paper thin. The extreme heat will instantly crispen the burger, almost into a chip. This is a smash burger. Immediately season and continue cooking until surface is a pale gray,"
    ),
    (
      "Foo",
      "Once surface is pale gray, flip, top the patties with slices of cheese, add a splash of water into the pan, add a lid and cook for 30 seconds. The cheesee will steam and the burger will be completely cooked."
    ),
    (
      "Foo",
      "Prepare for assembly!"
    )
    
  ]),
  .init(name: "Toppings", steps: [
    (
      "Foo",
      "Choose your toppings as you like and assemble as you like!"
    )
  ])
]

