import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class IngredientsListTests: XCTestCase {
  
  let ingredientsListReducerState: IngredientsListReducer.State = .init(
    ingredients: [
      .init(
        id: .init(),
        name: "Bread",
        ingredients: [
          .init(id: .init(), ingredient: .init(id: .init(), name: "flour", amount: 1, measure: "cup", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "yeast", amount: 1, measure: "tbsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "water", amount: 0.25, measure: "cup", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "salt", amount: 1, measure: "tsp", isComplete: false)),
        ],
        isExpanded: true,
        focusedField: nil
      ),
      .init(
        id: .init(),
        name: "Patties",
        ingredients: [
          .init(id: .init(), ingredient: .init(id: .init(), name: "chuck roast", amount: 2, measure: "lb", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "fat trimmmings", amount: 0.25, measure: "lb", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "msg", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "salt", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "pepper", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "garlic powder", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "onion powder", amount: 1, measure: "tsp", isComplete: false)),
        ],
        isExpanded: true,
        focusedField: nil
      ),
      .init(
        id: .init(),
        name: "Patties",
        ingredients: [
          .init(id: .init(), ingredient: .init(id: .init(), name: "chuck roast", amount: 2, measure: "lb", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "fat trimmmings", amount: 0.25, measure: "lb", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "msg", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "salt", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "pepper", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "garlic powder", amount: 1, measure: "tsp", isComplete: false)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "onion powder", amount: 1, measure: "tsp", isComplete: false)),
        ],
        isExpanded: true,
        focusedField: nil
      ),
      .init(
        id: .init(),
        name: "Toppingss",
        ingredients: [
          .init(id: .init(), ingredient: .init(id: .init(), name: "ketchup", amount: 1, measure: "to taste", isComplete: true)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "mustard", amount: 1, measure: "to taste", isComplete: true)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "mayo", amount: 1, measure: "to taste", isComplete: true)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "lettuce", amount: 1, measure: "to taste", isComplete: true)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "tomato", amount: 1, measure: "to taste", isComplete: true)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "onion", amount: 1, measure: "to taste", isComplete: true)),
          .init(id: .init(), ingredient: .init(id: .init(), name: "pickle chips", amount: 1, measure: "to taste", isComplete: true)),
        ],
        isExpanded: true,
        focusedField: nil
      )
    ],
    isExpanded: true
  )
  
  
  //case binding(BindingAction<State>)
  //case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
  //case isExpandedButtonToggled
  //case scaleStepperButtonTapped(Double)
  
  func testAddSectionButtonTapped() async {
    let store = TestStore(
      initialState: IngredientsListReducer.State(ingredients: [], isExpanded: true),
      reducer: IngredientsListReducer.init,
      withDependencies: {
        $0.uuid = .incrementing
        $0.continuousClock = ImmediateClock()
      }
    )
    
    await store.send(.addSectionButtonTapped) {
      $0.ingredients.append(.init(
        id: .init(rawValue: UUID(0)),
        name: "",
        ingredients: [],
        isExpanded: true,
        focusedField: .name
      ))
      $0.focusedField = .row(.init(rawValue: UUID(0)))
    }
    
    // MARK: - The view is really a switch, but this could still be called,
    await store.send(.addSectionButtonTapped) {
      $0.ingredients.append(.init(
        id: .init(rawValue: UUID(1)),
        name: "",
        ingredients: [],
        isExpanded: true,
        focusedField: .name
      ))
      $0.focusedField = .row(.init(rawValue: UUID(1)))
    }
  }
  
  func testIsExpandedButtonToggled() async {
    let store = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: IngredientsListReducer.State(
          ingredients: [
            .init(
              id: .init(rawValue: UUID(0)),
              name: "foo",
              ingredients: [
                .init(
                  id: .init(rawValue: UUID(1)),
                  focusedField: .name,
                  ingredient: .init(id: .init(rawValue: UUID(2)), name: "oats", amount: 1, measure: "cup", isComplete: false)
                )
              ],
              isExpanded: true,
              focusedField: .row(.init(rawValue: UUID(1)))
            )
          ],
          isExpanded: true,
          focusedField: .row(.init(rawValue: UUID(1)))
        ),
        reducer: IngredientsListReducer.init,
        withDependencies: {
          $0.uuid = .incrementing
          $0.continuousClock = ImmediateClock()
        }
      )
    }
    
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = false
      $0.focusedField = nil
      $0.ingredients[0].focusedField = nil
      $0.ingredients[0].ingredients[0].focusedField = nil
    }
    
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
  }
  
  func testScaleStepperButtonTapped() {
    let state: IngredientsListReducer.State = .init(
      ingredients: [
        .init(
          id: .init(),
          name: "Pound-Bread-A",
          ingredients: [
            .init(id: .init(), ingredient: .init(id: .init(), name: "honey", amount: 1, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "butter", amount: 2, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "eggs", amount: 3, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "flour", amount: 4, measure: "lb", isComplete: false)),
          ],
          isExpanded: true,
          focusedField: nil
        ),
        .init(
          id: .init(),
          name: "Pound-Bread-B",
          ingredients: [
            .init(id: .init(), ingredient: .init(id: .init(), name: "honey", amount: 10, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "butter", amount: 20, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "eggs", amount: 30, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "flour", amount: 40, measure: "lb", isComplete: false)),
          ],
          isExpanded: true,
          focusedField: nil
        ),
        .init(
          id: .init(),
          name: "Pound-Bread-C",
          ingredients: [
            .init(id: .init(), ingredient: .init(id: .init(), name: "honey", amount: 1.11, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "butter", amount: 2.22, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "eggs", amount: 3.33, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "flour", amount: 4.44, measure: "lb", isComplete: false)),
          ],
          isExpanded: true,
          focusedField: nil
        )
      ],
      isExpanded: true
    )
    
    let store = TestStore(
      initialState: state,
      reducer: IngredientsListReducer.init,
      withDependencies: {
        $0.uuid = .incrementing
        $0.continuousClock = ImmediateClock()
      }
    )
    
    store.send(.scaleStepperButtonTapped(1))
    store.send(.scaleStepperButtonTapped(2)) {
      $0.scale = 2
      
      $0.ingredients[0].ingredients[0].ingredient.amount = 2
      $0.ingredients[0].ingredients[0].ingredientAmountString = "2.0"
      $0.ingredients[0].ingredients[1].ingredient.amount = 4
      $0.ingredients[0].ingredients[1].ingredientAmountString = "4.0"
      $0.ingredients[0].ingredients[2].ingredient.amount = 6
      $0.ingredients[0].ingredients[2].ingredientAmountString = "6.0"
      $0.ingredients[0].ingredients[3].ingredient.amount = 8
      $0.ingredients[0].ingredients[3].ingredientAmountString = "8.0"

      $0.ingredients[1].ingredients[0].ingredient.amount = 20
      $0.ingredients[1].ingredients[0].ingredientAmountString = "20.0"
      $0.ingredients[1].ingredients[1].ingredient.amount = 40
      $0.ingredients[1].ingredients[1].ingredientAmountString = "40.0"
      $0.ingredients[1].ingredients[2].ingredient.amount = 60
      $0.ingredients[1].ingredients[2].ingredientAmountString = "60.0"
      $0.ingredients[1].ingredients[3].ingredient.amount = 80
      $0.ingredients[1].ingredients[3].ingredientAmountString = "80.0"
      
      $0.ingredients[2].ingredients[0].ingredient.amount = 2.22
      $0.ingredients[2].ingredients[0].ingredientAmountString = "2.22"
      $0.ingredients[2].ingredients[1].ingredient.amount = 4.44
      $0.ingredients[2].ingredients[1].ingredientAmountString = "4.44"
      $0.ingredients[2].ingredients[2].ingredient.amount = 6.66
      $0.ingredients[2].ingredients[2].ingredientAmountString = "6.66"
      $0.ingredients[2].ingredients[3].ingredient.amount = 8.88
      $0.ingredients[2].ingredients[3].ingredientAmountString = "8.88"
    }
    
    store.send(.scaleStepperButtonTapped(1)) {
      $0.ingredients = state.ingredients
      $0.scale = 1.0
    }
  }
  
  func testDelegateDeleteSection() async {
    let state: IngredientsListReducer.State = .init(
      ingredients: [
        .init(
          id: .init(rawValue: UUID(1)),
          name: "Pound-Bread-A",
          ingredients: [
            .init(id: .init(), ingredient: .init(id: .init(), name: "honey", amount: 1, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "butter", amount: 2, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "eggs", amount: 3, measure: "lb", isComplete: false)),
            .init(id: .init(), ingredient: .init(id: .init(), name: "flour", amount: 4, measure: "lb", isComplete: false)),
          ],
          isExpanded: true,
          focusedField: nil
        ),
      ],
      isExpanded: true
    )
    
    let store = TestStore(
      initialState: state,
      reducer: IngredientsListReducer.init
    )
    
    await store.send(.ingredient(.init(rawValue: UUID(1)), .delegate(.deleteSectionButtonTapped))) {
      $0.ingredients = []
    }
  }
  
  func testInsertSection() async {
    let store = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      let state: IngredientsListReducer.State = .init(
        ingredients: [
          .init(
            id: .init(rawValue: uuid()),
            name: "Pound-Bread-A",
            ingredients: [
              .init(id: .init(), ingredient: .init(id: .init(), name: "honey", amount: 1, measure: "lb", isComplete: false)),
              .init(id: .init(), ingredient: .init(id: .init(), name: "butter", amount: 2, measure: "lb", isComplete: false)),
              .init(id: .init(), ingredient: .init(id: .init(), name: "eggs", amount: 3, measure: "lb", isComplete: false)),
              .init(id: .init(), ingredient: .init(id: .init(), name: "flour", amount: 4, measure: "lb", isComplete: false)),
            ],
            isExpanded: true,
            focusedField: nil
          ),
        ],
        isExpanded: true
      )
      
      return TestStore(
        initialState: state,
        reducer: IngredientsListReducer.init
      )
    }
    
    XCTAssertTrue(store.state.ingredients.first!.id.uuidString == UUID(0).uuidString)
    
    await store.send(.ingredient(.init(rawValue: UUID(0)), .delegate(.insertSection(.above)))) {
      $0.ingredients.insert(
        .init(
          id: .init(rawValue: UUID(1)),
          name: "",
          ingredients: [],
          isExpanded: true,
          focusedField: .name
        ),
        at: 0
      )
      $0.focusedField = .row(.init(rawValue: UUID(1)))
    }
    
    XCTAssertTrue(store.state.ingredients.first!.id.uuidString == UUID(1).uuidString)
    
    await store.send(.ingredient(.init(rawValue: UUID(1)), .delegate(.insertSection(.below)))) {
      $0.ingredients.insert(
        .init(
          id: .init(rawValue: UUID(2)),
          name: "",
          ingredients: [],
          isExpanded: true,
          focusedField: .name
        ),
        at: 1
      )
      $0.ingredients[id: .init(rawValue: UUID(1))]?.focusedField = nil
      $0.focusedField = .row(.init(rawValue: UUID(2)))
    }
  }
}

