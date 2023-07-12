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
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: IngredientSectionReducer.State(
          id: .init(rawValue: uuid()),
          name: "foo",
          ingredients: .init(uniqueElements: [
            .init(
              id: .init(rawValue: uuid()),
              focusedField: nil,
              ingredient: .init(id: .init(rawValue: uuid())),
              emptyIngredientAmountString: true
            )
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
    XCTAssertTrue(store.state.id.uuidString == "00000000-0000-0000-0000-000000000000")
    XCTAssertTrue(store.state.ingredients[0].id.uuidString == "00000000-0000-0000-0000-000000000007")
    XCTAssertTrue(store.state.ingredients[1].id.uuidString == "00000000-0000-0000-0000-000000000008")
    XCTAssertTrue(store.state.ingredients[2].id.uuidString == "00000000-0000-0000-0000-000000000009")
    XCTAssertTrue(store.state.ingredients[3].id.uuidString == "00000000-0000-0000-0000-000000000010")
    XCTAssertTrue(store.state.ingredients[4].id.uuidString == "00000000-0000-0000-0000-000000000011")
    XCTAssertTrue(store.state.ingredients[5].id.uuidString == "00000000-0000-0000-0000-000000000012")
  }
}
