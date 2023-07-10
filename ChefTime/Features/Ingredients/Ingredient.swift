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
        Image(systemName: viewStore.ingredient.isComplete ? "checkmark.square" : "square")
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
      // TODO: Perhaps all .syncs should remove the .onAppear
      // and add a .onAppear reducer action case
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
      .foregroundColor(viewStore.ingredient.isComplete ? .secondary : .primary)
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
    private var _ingredientAmountString: String
    var ingredientAmountString: String {
      get {
        _ingredientAmountString
      }
      set {
        if let amount = Double(newValue) {
          _ingredientAmountString = newValue
          ingredient.amount = amount
        }
      }
    }
    
    init(
      id: ID,
      focusedField: FocusField? = nil,
      ingredient: Recipe.IngredientSection.Ingredient
    ) {
      self.id = id
      self.focusedField = focusedField
      self.ingredient = ingredient
      self._ingredientAmountString = String(ingredient.amount)
    }
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
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .binding:
        return .none
        
      case let .ingredientNameEdited(newName):
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
        
      case let .ingredientAmountEdited(newAmountString):
        if let amount = Double(newAmountString) {
          state.ingredient.amount = amount
          state.ingredientAmountString = newAmountString
        }
        return .none
        
      case let .ingredientMeasureEdited(newMeasure):
        state.ingredient.measure = newMeasure
        return .none
        
      case .isCompleteButtonToggled:
        state.ingredient.isComplete.toggle()
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
      case .delegate:
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
  let maxW: CGFloat = UIScreen.main.bounds.width * 0.90
  
  var body: some View {
    HStack(alignment: .top) {
      
      // Checkbox
      Image(systemName: state.ingredient.isComplete ? "checkmark.square" : "square")
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
    .foregroundColor(state.ingredient.isComplete ? .secondary : .primary)
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
            ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!
          ),
          reducer: IngredientReducer.init
        ))
        .padding()
      }
    }
  }
}
