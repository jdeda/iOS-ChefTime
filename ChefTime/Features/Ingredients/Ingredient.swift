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
struct IngredientView: View {
  let store: StoreOf<IngredientReducer>
  
  
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
        
        Rectangle()
          .fill(.clear)
          .frame(width: 50)
        
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
      .contextMenu(menuItems: {
        Button(role: .destructive) {
          viewStore.send(.delegate(.swipedToDelete), animation: .default)
        } label: {
          Text("Delete")
        }
      }, preview: {
        IngredientContextMenuPreview(state: viewStore.state)
          .padding()
      })
    }
  }
}

// MARK: - Reducer
struct IngredientReducer: ReducerProtocol {
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

extension IngredientReducer {
  enum DelegateAction: Equatable {
    case swipedToDelete
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
            ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!
          ),
          reducer: IngredientReducer.init
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

struct IngredientContextMenuPreview: View {
  let state: IngredientReducer.State
  
  var body: some View {
      HStack(alignment: .top) {
        
        // Checkbox
        Image(systemName: state.isComplete ? "checkmark.square" : "square")
          .fontWeight(.medium)
          .padding([.top], 2)
        
        // Name
        Text(!state.ingredient.name.isEmpty ? state.ingredient.name : "...")
          .lineLimit(1)
        
        Spacer()
        
        Rectangle()
          .fill(.clear)
          .frame(width: 50)
        
        // Amount
        Text(!state.ingredientAmountString.isEmpty ? state.ingredientAmountString : "...")
          .lineLimit(1)
        
        // Measurement
        Text(!state.ingredient.measure.isEmpty ? state.ingredient.measure : "...")
          .lineLimit(1)
      }
      .foregroundColor(state.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
  }
}
