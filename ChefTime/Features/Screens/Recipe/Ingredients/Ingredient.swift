import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// MARK: - View
struct IngredientView: View {
  let store: StoreOf<IngredientReducer>
  @FocusState private var focusedField: IngredientReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
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
        .onTapGesture { viewStore.send(.binding(.set(\.$focusedField, .name))) }
        
        Rectangle()
          .fill(.clear)
          .frame(width: 50)
        
        // Amount
        TextField("...", text: viewStore.$ingredientAmountString)
          .keyboardType(.decimalPad)
          .numbersOnly(viewStore.$ingredientAmountString, includeDecimal: true)
          .submitLabel(.next)
          .fixedSize()
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .focused($focusedField, equals: .amount)
          .onTapGesture { viewStore.send(.binding(.set(\.$focusedField, .amount))) }
        
        // Measurement
        TextField("...", text: viewStore.binding(
          get: { $0.ingredient.measure },
          send: { .ingredientMeasureEdited($0) }
        ))
        .fixedSize()
        .submitLabel(.next)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .measure)
        .onSubmit {
          viewStore.send(.delegate(.insertIngredient(.below)), animation: .default)
        }
        .onTapGesture { viewStore.send(.binding(.set(\.$focusedField, .measure))) }
        
      }
      .synchronize(viewStore.$focusedField, $focusedField)
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
struct IngredientReducer: Reducer {
  struct State: Equatable, Identifiable {
    var id: Recipe.IngredientSection.Ingredient.ID {
      self.ingredient.id
    }
    
    var ingredient: Recipe.IngredientSection.Ingredient
    @BindingState var ingredientAmountString: String
    var isComplete: Bool = false
    @BindingState var focusedField: FocusField? = nil
    
    init(
      ingredient: Recipe.IngredientSection.Ingredient,
      ingredientAmountString: String? = nil,
      isComplete: Bool = false,
      focusedField: FocusField? = nil
    ) {
      self.ingredient = ingredient
      self.ingredientAmountString = ingredientAmountString ?? String(ingredient.amount)
      self.isComplete = false
      self.focusedField = focusedField
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredientNameEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
    case keyboardDoneButtonTapped
    case keyboardNextButtonTapped
    case delegate(DelegateAction)
  }
  
  @Dependency(\.continuousClock) var clock
  
  private enum IngredientNameEditedID: Hashable { case timer }
  
  /// The textfields have the following mechanism:
  /// According the the following rules:
  /// 1. Name
  ///   1. if leading newline, don't update name and insert above
  ///   2. else trailing newline, don't update name and focus to amount
  ///   3. else, update name
  ///   4. user may tap done to dismiss and stop editing or next to move to the amount
  /// 2. Amount
  ///   0. assume that they can only type positive numbers with valid decimal checking
  ///   1. sync the amount string and the amount
  ///   2. can only change focus if keyboard button tapped
  ///   3. user may tap done to dismiss and stop editing or next to move to the measure
  /// 3. Measure
  ///   1. if trailing newline, don't update name and insert below
  ///   2. else, update name
  ///   3. on submit (trailing newline), insert below
  ///   4. user may tap done to dismiss and stop editing or next to insert below
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .binding(\.$ingredientAmountString):
        if state.ingredientAmountString == "" {
          state.ingredient.amount = 0
        }
        else if let amount = Double(state.ingredientAmountString) {
          state.ingredient.amount = amount
        }
        else {
          state.ingredientAmountString = String(state.ingredient.amount)
        }
        return .none
        
      case let .ingredientNameEdited(newName):
        if state.ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        let didEnter = DidEnter.didEnter(state.ingredient.name, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.ingredient.name = newName
          return .none
        case .leading:
          state.focusedField = nil
          return .run { send in
            try await self.clock.sleep(for: .microseconds(10))
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            /// This effect is also debounced to prevent multi additons as this action may be called from the a TextField
            /// which always emits twice when interacted with, which is a SwiftUI behavior:
            /// https://github.com/pointfreeco/swift-composable-architecture/discussions/800
            await send(.delegate(.insertIngredient(.above)), animation: .default)
          }
          .cancellable(id: IngredientNameEditedID.timer, cancelInFlight: true)
          
        case .trailing:
          state.focusedField = .amount
          return .none
        }
        
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
        // MARK: Would be nice if the name could perform leading
        // and trailing enters just like the text binding action for name.
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
            try await self.clock.sleep(for: .microseconds(10))
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            await send(.delegate(.insertIngredient(.below)), animation: .default)
          }
        case .none:
          return .none
        }
        
      case .delegate, .binding:
        return .none
      }
    }
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
  static let ingredient = Recipe.longMock.ingredientSections.first!.ingredients.first!
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientView(store: .init(
          initialState: .init(
            ingredient: ingredient
          ),
          reducer: IngredientReducer.init
        ))
        .padding()
      }
    }
  }
}
