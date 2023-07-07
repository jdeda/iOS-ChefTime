import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class IngredientTests: XCTestCase {
  
  func testIsCompleteButtonToggled() async {
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        ingredient: .init(id: .init()),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = ImmediateClock()
      }
    )
    
    XCTAssertTrue(store.state.ingredient.isComplete == false)
    await store.send(.isCompleteButtonToggled) {
      $0.ingredient.isComplete = true
    }
    await store.send(.isCompleteButtonToggled) {
      $0.ingredient.isComplete = false
    }
    await store.send(.isCompleteButtonToggled) {
      $0.ingredient.isComplete = true
    }
  }
  
  func testIngredientNameEdited() async {
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        ingredient: .init(id: .init(), name: "foo"),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = ImmediateClock()
      }
    )
    
    XCTAssertTrue(store.state.ingredient.name == "foo")
    /// In the UI, tapping a textfield will set the focus, so we don't have to
    /// set the focus ourselves, the view is handling that for us.
    await store.send(.ingredientNameEdited("foo"))
    await store.send(.ingredientNameEdited("foob")) {
      $0.ingredient.name = "foob"
    }
    await store.send(.ingredientNameEdited("fooby")) {
      $0.ingredient.name = "fooby"
    }
    await store.send(.ingredientNameEdited("foobar")) {
      $0.ingredient.name = "foobar"
    }
    
    /// This one is simulating pressing return on the keyboard.
    /// Note: you can skip this, but it is food for thought:
    /// One may consider if it possible to type or paste in a string that result in a newline
    /// that will automatically trigger the logic here to recognize that string as the user
    /// entering, causing behaviors that we don't want. Through a bit of typing and pasting
    /// into the UI it doesn't seem possible at least without a very deliberate attempt to do so.
    await store.send(.ingredientNameEdited("foo\n")) {
      $0.focusedField = .amount
    }
  }
}
