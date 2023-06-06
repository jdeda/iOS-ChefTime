import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// MARK: - View
struct IngredientView: View {
  let store: StoreOf<IngredientReducer>
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          TextField("Untitled Ingredient", text: viewStore.binding(
            get: { "\($0.ingredient.name)" },
            send: { .ingredientNameEdited($0) }
          ))
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .fontWeight(.medium)
          HStack(spacing: 0) {
            TextField("0  ", text: viewStore.binding(
              get: { $0.ingredientAmountString },
              send: { .ingredientAmountEdited($0) }
            ))
            .keyboardType(.numberPad)
            .numbersOnly(
              viewStore.binding(
                get: { $0.ingredientAmountString },
                send: { .ingredientAmountEdited($0) }
              ),
              includeDecimal: true
            )
            .frame(width: viewStore.ingredientAmountString.count > 0 ? CGFloat((viewStore.ingredientAmountString.count * 9) + 2) : CGFloat(20))
            // TODO: This must be formally done
            
            TextField("Untitled Measurement", text: viewStore.binding(
              get: { "\($0.ingredient.measure)" },
              send: { .ingredientMeasureEdited($0) }
            ))
            .autocapitalization(.none)
            .autocorrectionDisabled()
            Spacer()
          }
        }
        
        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
          .fontWeight(.medium)
          .onTapGesture {
            viewStore.send(.isCompleteButtonToggled)
          }
          .padding([.top], 2)
        //          .border(.orange)
        Spacer()
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
    }
  }
}

// MARK: - Reducer
struct IngredientReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredientNameEdited(String)
    case ingredientAmountEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .ingredientNameEdited(newName):
        state.viewState.ingredient.name = newName
        return .none
        
      case let .ingredientAmountEdited(newAmount):
        state.viewState.ingredientAmountString = newAmount
        return .none
        
      case let .ingredientMeasureEdited(newMeasure):
        state.viewState.ingredient.measure = newMeasure
        return .none
        
      case .isCompleteButtonToggled:
        state.viewState.isComplete.toggle()
        return .none
      }
    }
  }
}
extension IngredientReducer {
  struct ViewState: Equatable {
    var ingredient: Recipe.Ingredients.Ingredient
    var ingredientAmountString: String = ""
    var isComplete: Bool = false
    
    init(ingredient: Recipe.Ingredients.Ingredient) {
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
    }
  }
}

// MARK: - Previews
struct IngredientView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientView(store: .init(
          initialState: .init(
            id: .init(),
            viewState: .init(
              ingredient: Recipe.mock.ingredients.first!.ingredients.first!
            )
          ),
          reducer: IngredientReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .padding()
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
