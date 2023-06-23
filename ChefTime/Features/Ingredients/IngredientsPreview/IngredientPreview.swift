import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: Vertical Text Fields
// TODO: Number TextField still has bugs
//        1. fixed size means the row refreshes in a ugly way
//        2. typing invalid text still refreshes in a ugly way
//        3. sometimes editing another textfield moves text that
//           shouldn't move whatsoever

// MARK: - View
struct IngredientPreview: View {
  let store: StoreOf<IngredientPreviewReducer>
  
  struct ViewState: Equatable {
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool
    
    init(_ state: IngredientPreviewReducer.State) {
      self.ingredient = state.ingredient
      self.ingredientAmountString = state.ingredientAmountString
      self.isComplete = state.isComplete
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      HStack(alignment: .top) {
        
        // Checkbox
        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
          .fontWeight(.medium)
          .onTapGesture {
            viewStore.send(.isCompleteButtonToggled)
          }
          .padding([.top], 2)
        
        // Name
        TextField("...", text: .constant(viewStore.ingredient.name), axis: .vertical)
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .disabled(true)
        
        // Amount
        TextField("...", text: .constant(viewStore.ingredientAmountString))
          .fixedSize()
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .disabled(true)
        
        // Measurement
        TextField( "...", text: .constant(viewStore.ingredient.measure))
          .fixedSize()
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .disabled(true)
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
    }
  }
}

// MARK: - Reducer
// State.ingredientAmountString is used to handle number and string conversions
// for the "number text field". If the "number text field" is removed, this
// is probably no longer needed. This piece of state is certainly very confusing
// but the only I managed to figure out how to have a "number text field".
struct IngredientPreviewReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool
    
    init(id: ID, ingredient: Recipe.IngredientSection.Ingredient, isComplete: Bool = false) {
      self.id = id
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
      self.isComplete = false
    }
  }
  
  enum Action: Equatable {
    case isCompleteButtonToggled
    case none
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .isCompleteButtonToggled:
        state.isComplete.toggle()
        return .none
        
      case .none:
        return .none
      }
    }
  }
}

// MARK: - Previews
struct IngredientPreviewView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView
      {
        IngredientPreview(store: .init(
          initialState: .init(
            id: .init(),
            ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!
          ),
          reducer: IngredientPreviewReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
