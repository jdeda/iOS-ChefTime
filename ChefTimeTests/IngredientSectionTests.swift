import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class IngredientSectionTests: XCTestCase {
  
  let ingredients: IdentifiedArrayOf<IngredientReducer.State> = [
    .init(
      id: .init(rawValue: UUID(1)),
      focusedField: nil,
      ingredient: .init(id: .init(rawValue: UUID(2)), name: "figs", amount: 4, measure: "lbs", isComplete: false)
    ),
    .init(
      id: .init(rawValue: UUID(3)),
      focusedField: nil,
      ingredient: .init(id: .init(rawValue: UUID(4)), name: "brown sugar", amount: 1, measure: "cup", isComplete: false)
    ),
    .init(
      id: .init(rawValue: UUID(5)),
      focusedField: nil,
      ingredient: .init(id: .init(rawValue: UUID(6)), name: "butter", amount: 1, measure: "cup", isComplete: false)
    ),
  ]
  
  func testInit1() async {
    let store = {
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: IngredientSectionReducer.State(
          id: .init(rawValue: uuid()),
          name: "foo",
          ingredients: [],
          isExpanded: true,
          focusedField: nil
        ),
        reducer: IngredientSectionReducer.init,
        withDependencies: {
          $0.uuid = .incrementing
          $0.continuousClock = ImmediateClock()
        }
      )
    }()
    
    XCTAssertTrue(store.state.isExpanded == true)
    XCTAssertTrue(store.state.focusedField == nil)
    XCTAssertTrue(store.state.ingredients == [])
    XCTAssertTrue(store.state.name == "foo")
    XCTAssertTrue(store.state.id.uuidString == "00000000-0000-0000-0000-000000000000")
  }
  
  func testInit2() async {
    let store = {
      let uuid = UUIDGenerator.incrementing
      return TestStore(
        initialState: IngredientSectionReducer.State(
          id: .init(rawValue: uuid()),
          name: "foo",
          ingredients: .init(uniqueElements: [
            .init(id: .init(rawValue: uuid()), ingredient: .init(id: .init(rawValue: uuid()))),
            .init(id: .init(rawValue: uuid()), ingredient: .init(id: .init(rawValue: uuid()))),
            .init(id: .init(rawValue: uuid()), ingredient: .init(id: .init(rawValue: uuid()))),
            .init(id: .init(rawValue: uuid()), ingredient: .init(id: .init(rawValue: uuid()))),
          ]),
          isExpanded: true,
          focusedField: nil
        ),
        reducer: IngredientSectionReducer.init,
        withDependencies: {
          $0.uuid = .incrementing
          $0.continuousClock = ImmediateClock()
        }
      )
    }()
    
    XCTAssertTrue(store.state.isExpanded == true)
    XCTAssertTrue(store.state.focusedField == nil)
    XCTAssertTrue(store.state.name == "foo")
    XCTAssertTrue(store.state.ingredients.count == 4)
    
    XCTAssertTrue(store.state.id.uuidString == UUID(0).uuidString)
    XCTAssertTrue(store.state.ingredients[0].id.uuidString == UUID(1).uuidString)
    XCTAssertTrue(store.state.ingredients[0].ingredient.id.uuidString == UUID(2).uuidString)
    
    XCTAssertTrue(store.state.ingredients[1].id.uuidString == UUID(3).uuidString)
    XCTAssertTrue(store.state.ingredients[1].ingredient.id.uuidString == UUID(4).uuidString)
    
    XCTAssertTrue(store.state.ingredients[2].id.uuidString == UUID(5).uuidString)
    XCTAssertTrue(store.state.ingredients[2].ingredient.id.uuidString == UUID(6).uuidString)
    
    XCTAssertTrue(store.state.ingredients[3].id.uuidString == UUID(7).uuidString)
    XCTAssertTrue(store.state.ingredients[3].ingredient.id.uuidString == UUID(8).uuidString)
  }
  
  func testIsExpandedButtonToggled1() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "foo",
        ingredients: [],
        isExpanded: false,
        focusedField: nil
      ),
      reducer: IngredientSectionReducer.init
    )
    
    XCTAssertTrue(store.state.isExpanded == false)
    
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = false
    }
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = false
    }
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
  }
  
  func testIsExpandedButtonToggled2() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "foo",
        ingredients: [],
        isExpanded: true,
        focusedField: .name
      ),
      reducer: IngredientSectionReducer.init
    )
    
    XCTAssertTrue(store.state.isExpanded == true)
    
    await store.send(.isExpandedButtonToggled) {
      $0.focusedField = nil
      $0.isExpanded = false
    }
    
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
    
    await store.send(.binding(.set(\.$focusedField, .name))) {
      $0.focusedField = .name
    }
    
    await store.send(.isExpandedButtonToggled) {
      $0.focusedField = nil
      $0.isExpanded = false
    }
  }
  
  func testIsExpandedButtonToggled3() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "foo",
        ingredients: [
          .init(
            id: .init(rawValue: UUID(42)),
            focusedField: .name,
            ingredient: .init(id: .init(rawValue: UUID(43)))
          )
        ],
        isExpanded: true,
        focusedField: .row(.init(rawValue: UUID(42)))
      ),
      reducer: IngredientSectionReducer.init
    )
    
    XCTAssertTrue(store.state.isExpanded == true)
    XCTAssertTrue(store.state.focusedField == .row(.init(rawValue: UUID(42))))
    XCTAssertTrue(store.state.ingredients[id: .init(rawValue: UUID(42))]?.focusedField == .name)
    
    await store.send(.isExpandedButtonToggled) {
      $0.focusedField = nil
      $0.ingredients[id: .init(rawValue: UUID(42))]?.focusedField = nil
      $0.isExpanded = false
    }
    
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
  }
  
  func testIngredientSectionNameEdited() async {
    let clock = TestClock()
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "foo",
        ingredients: [],
        isExpanded: false,
        focusedField: .name
      ),
      reducer: IngredientSectionReducer.init) {
        $0.uuid = .incrementing
        $0.continuousClock = clock
      }
    
    XCTAssertTrue(store.state.focusedField == .name)
    XCTAssertTrue(store.state.name == "foo")
    
    await store.send(.ingredientSectionNameEdited("foob")) {
      $0.name = "foob"
    }
    await store.send(.ingredientSectionNameEdited("foob ")) {
      $0.name = "foob "
    }
    await store.send(.ingredientSectionNameEdited("")) {
      $0.name = ""
    }
    
    await store.send(.ingredientSectionNameEdited("foo")) {
      $0.name = "foo"
    }
    
    // Pasting an empty name should leave the name as empty and nothing else.
    await store.send(.ingredientSectionNameEdited("\n")) {
      $0.name = ""
    }
    
    // Clicking enter with nothing but whitespaces shouldn't trigger a keyboard dismiss.
    await store.send(.ingredientSectionNameEdited("\n"))
    await store.send(.ingredientSectionNameEdited("\n     "))
    await store.send(.ingredientSectionNameEdited("   \n"))
    
    
    await store.send(.ingredientSectionNameEdited("foobar")) {
      $0.name = "foobar"
    }
    
    // Clicking enter when there are no ingredients should trigger
    // automatically inserting one and focusing onto its name,
    // with a tiny delay and debouncing!
    await store.send(.ingredientSectionNameEdited("foobar\n")) {
      $0.focusedField = nil
    }
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientSectionNameEdited("foobar\n"))
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientSectionNameEdited("foobar\n"))
    await clock.advance(by: .microseconds(5))
    await store.send(.ingredientSectionNameEdited("foobar\n"))
    await clock.advance(by: .microseconds(10))
    await store.receive(.addIngredient, timeout: .microseconds(15)) {
      $0.ingredients.append(.init(
        id: .init(rawValue: UUID(0)),
        focusedField: .name,
        ingredient: .init(id: .init(rawValue: UUID(1)))
      ))
      $0.focusedField = .row(.init(rawValue: UUID(0)))
    }
    
    // Now if focus back onto the section name and press enter
    // nothing should happen
    await store.send(.binding(.set(\.$focusedField, .name))) {
      $0.focusedField = .name
    }
    await store.send(.ingredientSectionNameEdited("foobar\n")) {
      $0.focusedField = nil
    }
  }
  
  func testIngredientSectionNameDoneButtonTapped() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "foo",
        ingredients: [],
        isExpanded: false,
        focusedField: .name
      ),
      reducer: IngredientSectionReducer.init
    )
    
    XCTAssertTrue(store.state.focusedField == .name)
    await store.send(.ingredientSectionNameDoneButtonTapped) {
      $0.focusedField = nil
    }
  }
  
  func testRowTapped() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "Fig Jam",
        ingredients: ingredients,
        isExpanded: false,
        focusedField: nil
      ),
      reducer: IngredientSectionReducer.init
    )
    
    XCTAssertTrue(store.state.focusedField == nil)
    
    // Tap a row and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(1)))) {
      $0.focusedField = .row(.init(rawValue: UUID(1)))
    }
    guard let id = try? XCTUnwrap(
      (/IngredientSectionReducer.FocusField.row)
        .extract(from: store.state.focusedField)
    )
    else {
      XCTFail("id was nil")
      return
    }
    XCTAssertTrue(store.state.ingredients[id: id]! == ingredients[id: id]!)
    
    // Tap the same row. and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(1))))
    
    // Tap another row and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(3)))) {
      $0.focusedField = .row(.init(rawValue: UUID(3)))
    }
    guard let id = try? XCTUnwrap(
      (/IngredientSectionReducer.FocusField.row)
        .extract(from: store.state.focusedField)
    )
    else {
      XCTFail("id was nil")
      return
    }
    XCTAssertTrue(store.state.ingredients[id: id]! == ingredients[id: id]!)
    
    // Tap another row and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(5)))) {
      $0.focusedField = .row(.init(rawValue: UUID(5)))
    }
    guard let id = try? XCTUnwrap(
      (/IngredientSectionReducer.FocusField.row)
        .extract(from: store.state.focusedField)
    )
    else {
      XCTFail("id was nil")
      return
    }
    XCTAssertTrue(store.state.ingredients[id: id]! == ingredients[id: id]!)
  }
  
  func testSetFocus() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "Fig Jam",
        ingredients: ingredients,
        isExpanded: false,
        focusedField: nil
      ),
      reducer: IngredientSectionReducer.init
    )
    
    XCTAssertTrue(store.state.focusedField == nil)
    
    // Tap a row and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(1)))) {
      $0.focusedField = .row(.init(rawValue: UUID(1)))
    }
    guard let id = try? XCTUnwrap(
      (/IngredientSectionReducer.FocusField.row)
        .extract(from: store.state.focusedField)
    )
    else {
      XCTFail("id was nil")
      return
    }
    XCTAssertTrue(store.state.ingredients[id: id]! == ingredients[id: id]!)
    
    // Tap the same row. and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(1))))
    
    // Tap another row and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(3)))) {
      $0.focusedField = .row(.init(rawValue: UUID(3)))
    }
    guard let id = try? XCTUnwrap(
      (/IngredientSectionReducer.FocusField.row)
        .extract(from: store.state.focusedField)
    )
    else {
      XCTFail("id was nil")
      return
    }
    XCTAssertTrue(store.state.ingredients[id: id]! == ingredients[id: id]!)
    
    // Emulate tapping the section name to change focuses.
    await store.send(.binding(.set(\.$focusedField, .name))) {
      $0.focusedField = .name
      $0.ingredients[id: id]!.focusedField = nil
    }
    
    // Tap a row and make sure it matches up.
    await store.send(.rowTapped(.init(rawValue: UUID(5)))) {
      $0.focusedField = .row(.init(rawValue: UUID(5)))
    }
    guard let id = try? XCTUnwrap(
      (/IngredientSectionReducer.FocusField.row)
        .extract(from: store.state.focusedField)
    )
    else {
      XCTFail("id was nil")
      return
    }
    XCTAssertTrue(store.state.ingredients[id: id]! == ingredients[id: id]!)
  }
  
  func testDelegateTappedToDelete() async {
    let store = TestStore(
      initialState: IngredientSectionReducer.State(
        id: .init(rawValue: .init()),
        name: "Fig Jam",
        ingredients: ingredients,
        isExpanded: false,
        focusedField: nil
      ),
      reducer: IngredientSectionReducer.init
    )
    
    // First element signals itself for deletion.
    guard let first = try? XCTUnwrap(store.state.ingredients.first)
    else {
      XCTFail("should not be nil")
      return
    }
    await store.send(.ingredient(first.id, .delegate(.tappedToDelete))) {
      $0.ingredients.remove(id: .init(rawValue: UUID(1))) // Should be UUID(1)
    }
    
    // Delete something we are focused one.
    guard let first = try? XCTUnwrap(store.state.ingredients.first)
    else {
      XCTFail("should not be nil")
      return
    }
    await store.send(.rowTapped(first.id)) {
      $0.focusedField = .row(.init(rawValue: UUID(3))) // Should be UUID(3)
    }
    await store.send(.ingredient(first.id, .delegate(.tappedToDelete))) {
      $0.ingredients.remove(id: .init(rawValue: UUID(3))) // Should be UUID(1)
      $0.focusedField = nil
    }
  }
  
  func testDelegateInsertIngredient() async {
    let store = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: IngredientSectionReducer.State(
          id: .init(rawValue: uuid()),
          name: "Fig Jam",
          ingredients: [
            .init(
              id: .init(rawValue: uuid()),
              focusedField: nil,
              ingredient: .init(id: .init(rawValue: uuid()), name: "figs", amount: 4, measure: "lbs", isComplete: false)
            ),
            .init(
              id: .init(rawValue: uuid()),
              focusedField: nil,
              ingredient: .init(id: .init(rawValue: uuid()), name: "brown sugar", amount: 1, measure: "cup", isComplete: false)
            ),
            .init(
              id: .init(rawValue: uuid()),
              focusedField: nil,
              ingredient: .init(id: .init(rawValue: uuid()), name: "butter", amount: 1, measure: "cup", isComplete: false)
            ),
          ],
          isExpanded: false,
          focusedField: nil
        ),
        reducer: IngredientSectionReducer.init,
        withDependencies: {
          $0.uuid = .incrementing
        }
      )
    }
    
    // Focus onto a row and insert above.
    guard let first = try? XCTUnwrap(store.state.ingredients.first)
    else {
      XCTFail("should not be nil")
      return
    }
    await store.send(.rowTapped(first.id)) {
      $0.focusedField = .row(.init(rawValue: UUID(1))) // Should be UUID(3)
    }
    await store.send(.ingredient(first.id, .delegate(.insertIngredient(.above)))) {
      $0.ingredients.insert(.init(
        id: .init(rawValue: UUID(7)),
        focusedField: .name,
        ingredient: .init(id: .init(rawValue: UUID(8)))
      ), at: 0)
      $0.focusedField = .row(.init(rawValue: UUID(7)))
    }
    
    // Insert below.
    guard let first = try? XCTUnwrap(store.state.ingredients.first)
    else {
      XCTFail("should not be nil")
      return
    }
    await store.send(.ingredient(first.id, .delegate(.insertIngredient(.below)))) {
      $0.ingredients[id: first.id]?.focusedField = nil
      $0.ingredients.insert(.init(
        id: .init(rawValue: UUID(9)),
        focusedField: .name,
        ingredient: .init(id: .init(rawValue: UUID(10)))
      ), at: 1)
      $0.focusedField = .row(.init(rawValue: UUID(9)))
    }
  }
}
