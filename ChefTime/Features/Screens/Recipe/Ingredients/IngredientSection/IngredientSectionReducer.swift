import ComposableArchitecture

@Reducer
struct IngredientSectionReducer: Reducer  {
  struct State: Equatable, Identifiable {
    var id: Recipe.IngredientSection.ID { self.ingredientSection.id }
    var ingredientSection: Recipe.IngredientSection
    var ingredients: IdentifiedArrayOf<IngredientReducer.State> {
      didSet { self.ingredientSection.ingredients = self.ingredients.map(\.ingredient) }
    }
    @BindingState var isExpanded: Bool
    @BindingState var focusedField: FocusField?
    
    init(ingredientSection: Recipe.IngredientSection, focusedField: FocusField? = nil) {
      self.ingredientSection = ingredientSection
      self.ingredients = ingredientSection.ingredients.map{ .init(ingredient: $0) }
      self.isExpanded = true
      self.focusedField = focusedField
    }
  }
  
  @Dependency(\.uuid) var uuid
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredients(IdentifiedActionOf<IngredientReducer>)
    case ingredientSectionNameEdited(String)
    case ingredientSectionNameDoneButtonTapped
    case addIngredient
    case rowTapped(IngredientReducer.State.ID)
    
    case delegate(DelegateAction)
    @CasePathable
    enum DelegateAction: Equatable {
      case deleteSectionButtonTapped
      case insertSection(AboveBelow)
    }
  }
  
  @CasePathable
  @dynamicMemberLookup
  enum FocusField: Equatable, Hashable {
    case row(IngredientReducer.State.ID)
    case name
  }
  
  @Dependency(\.continuousClock) var clock
  
  private enum AddIngredientID: Hashable { case timer }
  
  var body: some Reducer<IngredientSectionReducer.State, IngredientSectionReducer.Action> {
    BindingReducer()
    Reduce<IngredientSectionReducer.State, IngredientSectionReducer.Action> { state, action in
      switch action {
      case let .ingredients(.element(id: id, action: .delegate(action))):
        switch action {
        case .tappedToDelete:
          // TODO: Animation can be a bit clunky, fix.
          if state.focusedField?.row == id {
            state.focusedField = nil
          }
          state.ingredients.remove(id: id)
          return .none
          
        case let .insertIngredient(aboveBelow):
          guard let i = state.ingredients.index(id: id) else { return .none }
          state.ingredients[id: id]?.focusedField = nil
          let s = IngredientReducer.State.init(
            ingredient: .init(id: .init(rawValue: uuid())),
            ingredientAmountString: "",
            focusedField: .name
          )
          state.ingredients.insert(s, at: aboveBelow == .above ? i : i + 1)
          state.focusedField = .row(s.id)
          return .none
        }
        
      case let .ingredientSectionNameEdited(newName):
        if state.ingredientSection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        if !state.ingredientSection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          state.ingredientSection.name = ""
          return .none
        }
        let didEnter = DidEnter.didEnter(state.ingredientSection.name, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.ingredientSection.name = newName
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if !state.ingredients.isEmpty { return .none }
          else {
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            /// This effect is also debounced to prevent multi additons as this action may be called from the a TextField
            /// which always emits twice when interacted with, which is a SwiftUI behavior:
            return .run { send in
              try await self.clock.sleep(for: .microseconds(10))
              await send(.addIngredient, animation: .default)
            }
            .cancellable(id: AddIngredientID.timer, cancelInFlight: true)
          }
        }
        
      case .ingredientSectionNameDoneButtonTapped:
        state.focusedField = nil
        return .none
        
      case let .rowTapped(id):
        state.focusedField = .row(id)
        return .none
        
      case .addIngredient:
        let s = IngredientReducer.State(
          ingredient: .init(id: .init(rawValue: uuid())),
          ingredientAmountString: "",
          focusedField: .name
        )
        state.ingredients.append(s)
        state.focusedField = .row(s.id)
        return .none

      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          if let currId = state.focusedField?.row {
            state.ingredients[id: currId]?.focusedField = nil
          }
          state.focusedField = nil
        }
        return .none
        
      case .delegate, .binding, .ingredients:
        return .none
      }
    }
    .forEach(\.ingredients, action: \.ingredients, element: IngredientReducer.init)
    .signpost()
  }
}
