import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: Number TextField still has bugs
//  1. fixed size means the row refreshes in a ugly way
//  2. typing invalid text still refreshes in a ugly way,
//     but this should be impossible from a device perspective
//  3. sometimes editing another textfield moves text
//     that shouldn't move whatsoever

// MARK: - View
struct IngredientLiveView: View {
  let store: StoreOf<IngredientLiveReducer>
  
  
  var body: some View {
    WithViewStore(store) { viewStore in
      HStack(alignment: .top) {
        
        // Checkbox
        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
          .fontWeight(.medium)
          .onTapGesture {
            viewStore.send(.isCompleteButtonToggled)
          }
          .padding([.top], 2)
        
        // Name
        TextField("...", text: viewStore.binding(\.$ingredient.name), axis: .vertical)
          .autocapitalization(.none)
          .autocorrectionDisabled()
        
        // Amount
        TextField("...", text: viewStore.binding(\.$ingredientAmountString))
          .keyboardType(.numberPad)
          .numbersOnly(viewStore.binding(\.$ingredientAmountString), includeDecimal: true)
          .fixedSize()
          .autocapitalization(.none)
          .autocorrectionDisabled()
        
        // Measurement
        TextField("...", text: viewStore.binding(\.$ingredient.measure))
          .fixedSize()
          .autocapitalization(.none)
          .autocorrectionDisabled()
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
      .swipeActions(content: {
        Button(role: .destructive) {
          viewStore.send(.delegate(.swipedToDelete), animation: .default)
        } label: {
          Image(systemName: "trash")
        }
      })
    }
  }
}

// MARK: - Reducer
struct IngredientLiveReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    @BindingState var ingredient: Recipe.IngredientSection.Ingredient
    @BindingState var ingredientAmountString: String
    var isComplete: Bool = false
    
    init(id: ID, ingredient: Recipe.IngredientSection.Ingredient) {
      self.id = id
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredientNameEdited(String)
    case ingredientAmountEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .binding:
        return .none
        
      case .binding(\.$ingredientAmountString):
        state.ingredient.amount = Double(state.ingredientAmountString) ?? 0
        return .none
        
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

extension IngredientLiveReducer {
  enum DelegateAction: Equatable {
    case swipedToDelete
  }
}

// MARK: - Previews
struct IngredientLiveView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      List
      {
        IngredientLiveView(store: .init(
          initialState: .init(
            id: .init(),
            ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!
          ),
          reducer: IngredientLiveReducer.init
        ))
      }
      .listStyle(.plain)
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
        if includeDecimal { numbers += decimalSeparator }
        if newValue.components(separatedBy: decimalSeparator).count-1 > 1 {
          let filtered = newValue
          self.text = String(filtered.dropLast())
        }
        else {
          let filtered = newValue.filter { numbers.contains($0) }
          if filtered != newValue { self.text = filtered }
        }
      }
  }
}
// MARK: - NumbersOnlyViewModifierExtension (Private)
private extension View {
  func numbersOnly(_ text: Binding<String>, includeDecimal: Bool = false) -> some View {
    self.modifier(NumbersOnlyViewModifier(text: text, includeDecimal: includeDecimal))
  }
}
