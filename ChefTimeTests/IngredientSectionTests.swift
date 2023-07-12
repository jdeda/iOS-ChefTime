import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class IngredientSectionTests: XCTestCase {
  
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
  
  //case binding(BindingAction<State>)
  //case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
  //case ingredientSectionNameEdited(String)
  //case ingredientSectionNameDoneButtonTapped
  //case addIngredient
  //case rowTapped(IngredientReducer.State.ID)
  //case setFocusedField(FocusField)
  //case delegate(DelegateAction)
  
  func testIsExpandedButtonToggled() async {
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
  
  func testIngredientSectionNameEdited() async {
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
    XCTAssertTrue(store.state.name == "foo")
    
    await store.send(.ingredientSectionNameEdited("foob")) {
      $0.name = "foob"
    }
    await store.send(.ingredientSectionNameEdited("foob ")) {
      $0.name = "foob "
    }
    await store.send(.ingredientSectionNameEdited("")) {
      $0.name = "foob"
    }
    
    await store.send(.ingredientSectionNameEdited("\n")) {
      $0.name = ""
    }
  }
}
