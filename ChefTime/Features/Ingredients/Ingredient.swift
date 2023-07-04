import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

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
        // TODO: Sometimes editing another textfield moves text that shouldn't move whatsoever
        TextField(
          "...",
          text: viewStore.binding(
            get: \.ingredient.name,
            send: {
              .ingredientNameEdited($0)
            }
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
        // TODO: This NumberTextField still has bugs
        //  1. fixed size means the row refreshes in a ugly way
        //  2. typing invalid text still refreshes in a ugly way,
        //     but this should be impossible from a device perspective
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
      .toolbar {
        if viewStore.focusedField != nil {
          ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("next") {
              viewStore.send(.keyboardNextButtonTapped, animation: .default)
            }
            .foregroundColor(.primary)
            Button("done") {
              viewStore.send(.keyboardDoneButtonTapped, animation: .default)
            }
            .foregroundColor(.primary)
          }
        }
      }
      .accentColor(.accentColor)
      .contextMenu(menuItems: {
        Button(role: .destructive) {
          viewStore.send(.delegate(.tappedToDelete), animation: .default)
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
    @BindingState var focusedField: FocusField? = nil
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String // This string must be synchronized with the ingredient.amount and is used for the ingredient amount textfield.
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
  
  @Dependency(\.continuousClock) var clock
  
  private enum IngredientNameEditedID: Hashable { case timer }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .binding:
        return .none
        
      case let .ingredientNameEdited(newName):
        // TODO: bug where spam clicking very fast return will get a new line character stuck
        if state.ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        let oldName = state.ingredient.name
        state.ingredient.name = newName
        let didEnter = DidEnter.didEnter(oldName, newName)
        switch didEnter {
        case .didNotSatisfy:
          return .none
        case .leading:
          // Keep the original string because only trailing or leading spaces were added.
          state.ingredient.name = oldName
          state.focusedField = nil
          /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
          /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
          /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
          /// This effect is also debounced to prevent multi additons as this action may be called from the a TextField
          /// which always emits twice when interacted with, which is a SwiftUI behavior:
          /// https://github.com/pointfreeco/swift-composable-architecture/discussions/800
          return .run { send in
            try await self.clock.sleep(for: .microseconds(10))
            await send(.delegate(.insertIngredient(.above)), animation: .default)
          }
          .cancellable(id: IngredientNameEditedID.timer, cancelInFlight: true)
          
        case .trailing:
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
        // TODO: Would be nice if the name could perform leading and trailing enters just like the text binding action for name.
        // However it does not seem easy or nice to do so.
        switch state.focusedField {
        case .name:
          state.focusedField = .amount
          return .none
        case .amount:
          state.focusedField = .measure
          return .none
        case .measure:
          state.focusedField = nil
          return .run { send in
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            try await self.clock.sleep(for: .microseconds(10))
            await send(.delegate(.insertIngredient(.below)), animation: .default)
          }
        case .none:
          return .none
        }
      case .delegate:
        return .none
      }
    }
    ._printChanges()
  }
}

// MARK: - DelegateAction
extension IngredientReducer {
  enum DelegateAction: Equatable {
    case tappedToDelete
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
  let maxW: CGFloat = UIScreen.main.bounds.width * 0.90
  
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

// MARK: - Previews
struct IngredientView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientView(store: .init(
          initialState: .init(
            id: .init(),
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
