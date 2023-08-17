import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class IngredientTests: XCTestCase {
  
  func testInit1() async {
    // Initialize a default state.
    let state = IngredientReducer.State(id: .init(), ingredient: .init(id: .init()), ingredientAmountString: "")
    XCTAssertTrue(state.ingredient.name == "")
    XCTAssertTrue(state.ingredient.amount == 0)
    XCTAssertTrue(state.ingredient.measure == "")
    XCTAssertTrue(state.ingredient.isComplete == false)
    XCTAssertTrue(state.focusedField == nil)
    XCTAssertTrue(state.ingredientAmountString == "")
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
      ), ingredientAmountString: "2.0"
    )
    XCTAssertTrue(state.ingredient.name == "butter")
    XCTAssertTrue(state.ingredient.amount == 2.0)
    XCTAssertTrue(state.ingredient.measure == "cups")
    XCTAssertTrue(state.ingredient.isComplete == true)
    XCTAssertTrue(state.focusedField == .name)
    XCTAssertTrue(state.ingredientAmountString == "2.0")
  }
  
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
        ingredient: .init(id: .init(), name: "foo"), ingredientAmountString: ""
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
    } // MARK: - Debounce or nah?
    
    // Simulate user tapping back onto the name.
    await store.send(.set(\.$focusedField, .name))  {
      $0.focusedField = .name
    }
    
    // Test pressing enter at the beginning of an empty name.
    await store.send(.ingredientNameEdited("")) { $0.ingredient.name = "" }
    await store.send(.ingredientNameEdited("\n"))
    await store.send(.ingredientNameEdited(" "))
    await store.send(.ingredientNameEdited("       "))
    
    await store.send(.ingredientNameEdited(" foobar ")) {
      $0.ingredient.name = " foobar "
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
    // MARK: May fail due to nondeterminism

    // Make sure all in-flight effects are done.
    await clock.advance(by: .seconds(5))
    await store.finish(timeout: .microseconds(20))
    
    // Try lots of debounces.
    await store.send(.set(\.$focusedField, .name)) { $0.focusedField = .name }
    await store.send(.ingredientNameEdited("\n foobar ")) { $0.focusedField = nil }
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientNameEdited("\n foobar "))
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientNameEdited("\n foobar "))
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientNameEdited("\n foobar "))
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientNameEdited("\n foobar "))
    await clock.advance(by: .microseconds(15))
    await store.receive(.delegate(.insertIngredient(.above)))
    // MARK: May fail due to nondeterminism
  }
  
  func testIngredientAmountEdited() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        focusedField: .name, // Assume we are focused on the name for starts.
        ingredient: .init(id: .init(), name: "foo"),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    
    XCTAssertTrue(store.state.ingredientAmountString == "")
    XCTAssertTrue(store.state.ingredient.amount == 0)
    
    await store.send(.ingredientAmountEdited(""))
    await store.send(.ingredientAmountEdited("."))
    await store.send(.ingredientAmountEdited("foo"))

    await store.send(.ingredientAmountEdited("0.2")) {
      $0.ingredientAmountString = "0.2"
      $0.ingredient.amount = 0.2
    }

    await store.send(.ingredientAmountEdited("0.")) {
      $0.ingredientAmountString = "0."
      $0.ingredient.amount = 0
    }

    await store.send(.ingredientAmountEdited("0")) {
      $0.ingredientAmountString = "0"
    }
  }
  
  func testIngredientMeasureEdited() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        focusedField: .name, // Assume we are focused on the name for starts.
        ingredient: .init(id: .init(), name: "foo"),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    
    await store.send(.ingredientMeasureEdited("foo")) {
      $0.ingredient.measure = "foo"
    }
    
    // This should not insert below, as this textfield uses .onSubmit
    await store.send(.ingredientMeasureEdited("foo\n")) {
      $0.ingredient.measure = "foo\n"
    }
    
    await store.send(.ingredientMeasureEdited("foo")) { $0.ingredient.measure = "foo" }
    await store.send(.ingredientMeasureEdited("fo")) { $0.ingredient.measure = "fo" }
    await store.send(.ingredientMeasureEdited("f")) { $0.ingredient.measure = "f" }
    await store.send(.ingredientMeasureEdited("")) { $0.ingredient.measure = "" }
    await store.send(.ingredientMeasureEdited("FOOBAR")) { $0.ingredient.measure = "FOOBAR" }
  }
  
  
  func testKeyboardDoneButtonTapped() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        ingredient: .init(id: .init(), name: "foo"),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    XCTAssertTrue(store.state.focusedField == nil)
    
    // Simulate user tapping onto the name then taps done.
    await store.send(.set(\.$focusedField, .name)) { $0.focusedField = .name }
    await store.send(.keyboardDoneButtonTapped) { $0.focusedField = nil }
    
    // Simulate user tapping onto the amount then taps done.
    await store.send(.set(\.$focusedField, .amount)) { $0.focusedField = .amount }
    await store.send(.keyboardDoneButtonTapped) { $0.focusedField = nil }
    
    // Simulate user tapping onto the measure then taps done.
    await store.send(.set(\.$focusedField, .measure)) { $0.focusedField = .measure }
    await store.send(.keyboardDoneButtonTapped) { $0.focusedField = nil }
  }
  
  func testKeyboardNextButtonTapped() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        ingredient: .init(id: .init(), name: "foo"),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    XCTAssertTrue(store.state.focusedField == nil)
    await store.send(.keyboardNextButtonTapped)

    await store.send(.set(\.$focusedField, .name)) { $0.focusedField = .name }
    await store.send(.keyboardNextButtonTapped) { $0.focusedField = .amount }
    await store.send(.keyboardNextButtonTapped) { $0.focusedField = .measure }
    await store.send(.keyboardNextButtonTapped) { $0.focusedField = nil }
    await clock.advance(by: .microseconds(10))
    await store.receive(.delegate(.insertIngredient(.below)), timeout: .microseconds(10))
  }
}
