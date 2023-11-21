import SwiftUI
import ComposableArchitecture

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

extension IngredientReducer {
  enum DelegateAction: Equatable {
    case tappedToDelete
    case insertIngredient(AboveBelow)
  }
}

extension IngredientReducer {
  enum FocusField: Equatable {
    case name
    case amount
    case measure
  }
}
