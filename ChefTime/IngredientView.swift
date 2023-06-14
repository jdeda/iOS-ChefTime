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
struct IngredientView: View {
  let store: StoreOf<IngredientReducer>
  
  struct ViewState: Equatable {
    var ingredient: Recipe.Ingredients.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool = false
    
    init(_ state: IngredientReducer.State) {
      self.ingredient = state.ingredient
      self.ingredientAmountString = state.ingredientAmountString
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
            send: { .ingredientNameEdited($0) }
          ),
          axis: .vertical
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        // Amount
        TextField(
          "...",
          text: viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { .ingredientAmountEdited($0) }
          )
        )
        .keyboardType(.numberPad)
        .numbersOnly(
          viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { .ingredientAmountEdited($0) }
          ),
          includeDecimal: true
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        // Measurement
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.measure)" },
            send: { .ingredientMeasureEdited($0) }
          )
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
      .contextMenu {
        // TODO: This would be nice as a swipe action.
        Button(role: .destructive){
          viewStore.send(.delegate(.swipedToDelete), animation: .default)
        } label: {
          Text("Delete")
        }
      }
    }
  }
}

// MARK: - Reducer
struct IngredientReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var ingredient: Recipe.Ingredients.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool = false
    
    init(id: ID, ingredient: Recipe.Ingredients.Ingredient) {
      self.id = id
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
    }
  }
  
  enum Action: Equatable {
    case ingredientNameEdited(String)
    case ingredientAmountEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .ingredientNameEdited(newName):
        state.ingredient.name = newName
        return .none
        
      case let .ingredientAmountEdited(newAmountString):
        // TODO: Fix...
        state.ingredientAmountString = newAmountString
        state.ingredient.amount = Double(newAmountString) ?? 0
        return .none
        
      case let .ingredientMeasureEdited(newMeasure):
        state.ingredient.measure = newMeasure
        return .none
        
      case .isCompleteButtonToggled:
        state.isComplete.toggle()
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

extension IngredientReducer {
  enum DelegateAction: Equatable {
    case swipedToDelete
  }
}

// MARK: - Previews
struct IngredientView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView
      {
        IngredientView(store: .init(
          initialState: .init(
            id: .init(),
            ingredient: Recipe.mock.ingredients.first!.ingredients.first!
          ),
          reducer: IngredientReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .listStyle(.plain)
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

// TODO: RENAME THS
struct IngredientViewX: View {
  var body: some View {
    HStack(alignment: .top) {
      
      // Checkbox
      Image(systemName: "square")
        .fontWeight(.medium)
        .padding([.top], 2)
      
      // Name
      TextField("...", text: .constant(""))
        .disabled(true)
      
      // Amount
      TextField("...", text: .constant(""))
        .disabled(true)
        .fixedSize()
      
      // Measurement
      TextField("...", text: .constant(""))
        .disabled(true)
        .fixedSize()
      
      Image(systemName: "plus")
        .fontWeight(.medium)
        .padding([.top], 2)
    }
    .foregroundColor(.secondary)
    .accentColor(.accentColor)
  }
}
