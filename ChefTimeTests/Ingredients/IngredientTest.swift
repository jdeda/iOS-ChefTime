import XCTest
import ComposableArchitecture


@testable import ChefTime

@MainActor
final class IngredientTests: XCTest {
  func testCheckbox() async {
    // TODO: Control init UUID on the test store?
    let store = TestStore(
      initialState: IngredientReducer.State(
        id: .init(),
        ingredient: .init(id: .init()),
        ingredientAmountString: ""
      ),
      reducer: IngredientReducer.init,
      withDependencies: {
         $0.uuid = .incrementing
      }
    )
    
    XCTAssertTrue(store.state.ingredient.isComplete == true)
    await store.send(.isCompleteButtonToggled) {
      $0.ingredient.isComplete = true
    }
  }
  
  func testNameTextFieldEdited() {
    
  }
  
  func testAmountTextFieldEdited() {
    
  }
  
  func testMeasureTextFieldEdited() {
    
  }
  
}
