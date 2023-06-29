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
  @FocusState private var focusedField: IngredientReducer.FocusField?
  
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
        TextField(
          "...",
          text: viewStore.binding(
            get: \.ingredient.name,
            send: { .ingredientNameEdited($0) }
          ),
          axis: .vertical
        )
        .submitLabel(.next)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .name)
        
        Rectangle()
          .fill(.clear)
          .frame(width: 50)
        
        // Amount
        TextField(
          "...",
          text: viewStore.binding(
            get: \.ingredientAmountString,
            send: { .ingredientAmountEdited($0) }
          )
        )
        .keyboardType(.decimalPad)
        .numbersOnly(viewStore.binding(
          get: \.ingredientAmountString,
          send: { .ingredientAmountEdited($0) }
        ), includeDecimal: true)
        .submitLabel(.next)
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .amount)
        .toolbar {
          if viewStore.isSelected {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              if viewStore.focusedField == .amount {
                Button("next") {
                  viewStore.send(.keyboardNextButtonTapped)
                }
              }
              Button("done") {
                viewStore.send(.keyboardDoneButtonTapped)
              }
            }
          }
        }
        
        // Measurement
        TextField(
          "...",
          text: viewStore.binding(
            get: \.ingredient.measure,
            send: { .ingredientMeasureEdited($0) }
          )
        )
        .fixedSize()
        .submitLabel(.next)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .measure)
        .onSubmit {
          viewStore.send(.delegate(.insertIngredient(.below)), animation: .default)
        }
        
      }
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
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
    let isSelected: Bool
    @BindingState var focusedField: FocusField? = nil
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool = false
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredientNameEdited(String)
    case ingredientAmountEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
    case keyboardDoneButtonTapped
    case keyboardNextButtonTapped
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .binding:
        return .none
        
      case let .ingredientNameEdited(newName):
        let oldName = state.ingredient.name
        state.ingredient.name = newName
        let didEnter = didEnter(oldName, newName)
        switch didEnter {
        case .didNotSatisfy:
          return .none
        case .beginning:
          // Keep the original string because only trailing or leading spaces were added.
          state.ingredient.name = oldName
          state.focusedField = nil
          
          /// MARK: - There is a strange bug where sending this action without
          /// briefly waiting, for even a nanosecond prevents focus state,
          /// animations, and possibly even more from working as expected.
          /// This only happens when performing additional logic in a TextField binding
          /// This little sleep saves the day, and may only take a nanosecond. It
          /// somehow allows the logic run within the TextField binding to work
          /// properly amogst this reducer and parent reducers and views.
          return .run { send in
            try await Task.sleep(for: .nanoseconds(1))
            await send(.delegate(.insertIngredient(.above)), animation: .default)
          }
        case .end:
          // Keep the original string because only trailing or leading spaces were added.
          state.ingredient.name = oldName
          state.focusedField = .amount
          return .none
        }
        
      case let .ingredientAmountEdited(newAmountString):
        state.ingredientAmountString = newAmountString
        state.ingredient.amount = Double(newAmountString) ?? 0
        return .none
        
      case let .ingredientMeasureEdited(newMeasure):
        state.ingredient.measure = newMeasure
        return .none
        
      case .isCompleteButtonToggled:
        state.isComplete.toggle()
        return .none
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
        
      case .keyboardNextButtonTapped:
        guard state.focusedField == .amount else { return .none }
        state.focusedField = .measure
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - DelegateAction
extension IngredientReducer {
  enum DelegateAction: Equatable {
    case swipedToDelete
    case insertIngredient(AboveBelow)
  }
}

// MARK: - FocusField
extension IngredientReducer {
  enum FocusField: Equatable {
    case name
    case amount
    case measure
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

// MARK: - IngredientContextMenuPreview
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

// MARK: - TextField didEnter helper.
/// Determines if and where the `TextField` has entered, either at the beginning or end of the new string.
/// Returns a DidEnter enumeration representing:
/// - didNotSatisfy - if the new value has not satisfied the parameters for a valid return
/// - beginning - if the value has satisfied the parameters for a valid return, and did so via the beginning
/// - end - if the value has satisfied the parameters for a valid return, and did so via the end
enum DidEnter: Equatable {
  case didNotSatisfy
  case beginning
  case end
}

private func didEnter(_ old: String, _ new: String) -> DidEnter {
  guard !old.isEmpty, !new.isEmpty
  else { return .didNotSatisfy }
  
  let newSafe = new
  
  var new = newSafe
  let lastCharacter = new.removeLast()
  if old == new && lastCharacter.isNewline {
    return .end
  }
  else {
    var new = newSafe
    let firstCharacter = new.removeFirst()
    if old == new && firstCharacter.isNewline {
      return .beginning
    }
  }
  return .didNotSatisfy
}

// MARK: - Previews
struct IngredientView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientView(store: .init(
          initialState: .init(
            id: .init(),
            isSelected: true,
            focusedField: nil,
            ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!,
            ingredientAmountString: String(Recipe.longMock.ingredientSections.first!.ingredients.first!.amount),
            isComplete: false
          ),
          reducer: IngredientReducer.init
        ))
        .padding()
      }
    }
  }
}
