import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: Vertical Text Fields
// TODO: Swipe Gestures
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
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.name)" },
            send: { _ in .none }
          ),
          axis: .vertical
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .disabled(true)
        
        // Amount
        TextField(
          "...",
          text: viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { _  in .none }
          )
        )
        .keyboardType(.numberPad)
        .numbersOnly(
          viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { _  in .none }
          ),
          includeDecimal: true
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .disabled(true)
        
        // Measurement
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.measure)" },
            send: { _  in .none }
          )
        )
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
struct IngredientPreviewReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool = false
    
    init(id: ID, ingredient: Recipe.IngredientSection.Ingredient) {
      self.id = id
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
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

// MARK: - NumbersOnlyViewModifier (Private)
private struct NumbersOnlyViewModifier: ViewModifier {
  @Binding var text: String
  var includeDecimal: Bool
  
  func body(content: Content) -> some View {
    content
      .keyboardType(includeDecimal ? .decimalPad : .numberPad)
      .onReceive(Just(text)) { newValue in
        var numbers = "0123456789"
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        if includeDecimal {
          numbers += decimalSeparator
        }
        if newValue.components(separatedBy: decimalSeparator).count-1 > 1 {
          let filtered = newValue
          self.text = String(filtered.dropLast())
        }
        else {
          let filtered = newValue.filter { numbers.contains($0) }
          if filtered != newValue {
            self.text = filtered
          }
        }
      }
  }
}

private extension View {
  func numbersOnly(_ text: Binding<String>, includeDecimal: Bool = false) -> some View {
    self.modifier(NumbersOnlyViewModifier(text: text, includeDecimal: includeDecimal))
  }
}
