import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class IngredientTests: XCTestCase {
  
  func testInit1() async {
    // Initialize a default state.
    let state = IngredientReducer.State(id: .init(), ingredient: .init(id: .init()))
    XCTAssertTrue(state.ingredient.name == "")
    XCTAssertTrue(state.ingredient.amount == 0)
    XCTAssertTrue(state.ingredient.measure == "")
    XCTAssertTrue(state.ingredient.isComplete == false)
    XCTAssertTrue(state.focusedField == nil)
    XCTAssertTrue(state.ingredientAmountString == "0.0")
  }

  func testInit2() async {
    // Initialize a fully configured state.
    let state = IngredientReducer.State(
      id: .init(),
      focusedField: .name,
      ingredient: .init(
        id: .init(),
        name: "butter",
        amount: 2.0,
        measure: "cups",
        isComplete: true
      )
    )
    XCTAssertTrue(state.ingredient.name == "butter")
    XCTAssertTrue(state.ingredient.amount == 2.0)
    XCTAssertTrue(state.ingredient.measure == "cups")
    XCTAssertTrue(state.ingredient.isComplete == true)
    XCTAssertTrue(state.focusedField == .name)
    XCTAssertTrue(state.ingredientAmountString == "2.0")
  }
  
  func testIngredientAmountString1() async {
    var state = IngredientReducer.State(id: .init(), ingredient: .init(id: .init()))
    XCTAssertTrue(state.ingredient.amount == 0.0)
    XCTAssertTrue(state.ingredientAmountString == "0.0")
    
    state.ingredientAmountString = "0.01"
    XCTAssertTrue(state.ingredientAmountString == "0.01")
    XCTAssertTrue(state.ingredient.amount == 0.01)
    
    state.ingredientAmountString = ".01"
    XCTAssertTrue(state.ingredientAmountString == ".01")
    XCTAssertTrue(state.ingredient.amount == 0.01)
    
    state.ingredientAmountString = "1/2"
    XCTAssertTrue(state.ingredientAmountString == "0.01")
    XCTAssertTrue(state.ingredient.amount == 0.01)
  }
  
  func testIngredientAmountStrin2() async {
    var state = IngredientReducer.State(id: .init(), ingredient: .init(id: .init()))
    XCTAssertTrue(state.ingredient.amount == 0.0)
    XCTAssertTrue(state.ingredientAmountString == "0.0")
    
    state.ingredient.amount = "0.01"
    XCTAssertTrue(state.ingredientAmountString == "0.01")
    XCTAssertTrue(state.ingredient.amount == 0.01)
    
    state.ingredientAmountString = ".01"
    XCTAssertTrue(state.ingredientAmountString == ".01")
    XCTAssertTrue(state.ingredient.amount == 0.01)
    
    state.ingredientAmountString = "1/2"
    XCTAssertTrue(state.ingredientAmountString == "0.01")
    XCTAssertTrue(state.ingredient.amount == 0.01)
  }
  
  func testIsCompleteButtonToggled() async {
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        ingredient: .init(id: .init())
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
  
  /// Tests user typing values into the name as well as keyboard entering,
  /// The following comments describe food for thought:
  /// One may consider if it possible to type or paste in a string that result in a newline
  /// that will automatically trigger the logic here to recognize that string as the user
  /// entering, causing behaviors that we don't want. Through a bit of typing and pasting
  /// into the UI it doesn't seem possible at least without a very deliberate attempt to do so.
  /// ```
  /// await store.send(.ingredientNameEdited("foo\n")) {
  ///   $0.focusedField = .amount
  /// }
  /// ```
  func testIngredientNameEdited() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        focusedField: .name, // Assume we are focused on the name for starts.
        ingredient: .init(id: .init(), name: "foo")
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    
    XCTAssertTrue(store.state.focusedField == .name)
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
    await store.send(.ingredientNameEdited(" foobar")) {
      $0.ingredient.name = " foobar"
    }
    await store.send(.ingredientNameEdited(" foobar ")) {
      $0.ingredient.name = " foobar "
    }
    
    // Test pressing enter at the end of the name.
    await store.send(.ingredientNameEdited(" foobar \n")) {
      $0.focusedField = .amount
    }
    
    // Simulate user tapping back onto the name.
    await store.send(.set(\.$focusedField, .name))  {
      $0.focusedField = .name
    }
    
    // Test pressing enter at the beginning of the name.
    await store.send(.ingredientNameEdited("\n foobar ")) { $0.focusedField = nil }
    await clock.advance(by: .microseconds(20))
    await store.receive(.delegate(.insertIngredient(.above)))
    
    // Make sure all in-flight effects are done.
    await clock.advance(by: .seconds(5))
    await store.finish(timeout: .microseconds(20))
    
    // Simulate user tapping back onto the name.
    await store.send(.set(\.$focusedField, .name)) {
      $0.focusedField = .name
    }
    
    // Test pressing enter at the beginning of the name, twice,
    // to simulate textfield double emissions.
    await store.send(.ingredientNameEdited("\n foobar ")) { $0.focusedField = nil }
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientNameEdited("\n foobar "))
    await clock.advance(by: .microseconds(15))
    await store.receive(.delegate(.insertIngredient(.above)))

    // Make sure all in-flight effects are done.
    await clock.advance(by: .seconds(5))
    await store.finish(timeout: .microseconds(20))
  }
  
  func testIngredientAmountEdited() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        focusedField: .name, // Assume we are focused on the name for starts.
        ingredient: .init(id: .init(), name: "foo")
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    //     TODO: UI u must double back to get empty str for some reason
//    await store.send(.ingredientAmountEdited("")) {
//      $0.ingredientAmountString = "0"
//      $0.ingredient.amount = 0
//    }
//    await store.send(.ingredientAmountEdited("."))
//
//    await store.send(.ingredientAmountEdited("0.2")) {
//      $0.ingredientAmountString = "0.2"
//      $0.ingredient.amount = 0.2
//    }
//
//    await store.send(.ingredientAmountEdited("0.")) {
//      $0.ingredientAmountString = "0"
//      $0.ingredient.amount = 0
//    }
//
//    await store.send(.ingredientAmountEdited("0"))
  }
}
