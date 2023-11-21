import ComposableArchitecture

@Reducer
struct StepSectionReducer  {
  struct State: Equatable, Identifiable {
    var id: Recipe.StepSection.ID { self.stepSection.id }
    var stepSection: Recipe.StepSection
    var steps: IdentifiedArrayOf<StepReducer.State> {
      didSet { self.stepSection.steps = steps.map(\.step) }
    }
    @BindingState var isExpanded: Bool
    @BindingState var focusedField: FocusField?
    
    init(stepSection: Recipe.StepSection, focusedField: FocusField? = nil) {
      self.stepSection = stepSection
      self.steps = stepSection.steps.map { .init(step: $0) }
      self.isExpanded = true
      self.focusedField = focusedField
    }
  }
  
  enum Action: Equatable, BindableAction {
    case steps(IdentifiedActionOf<StepReducer>)
    case binding(BindingAction<State>)
    case stepSectionNameEdited(String)
    case addStep
    case keyboardDoneButtonTapped
    case stepSectionUpdate
    
    case delegate(DelegateAction)
    @CasePathable
    enum DelegateAction: Equatable {
      case deleteSectionButtonTapped
      case insertSection(AboveBelow)
    }
  }
  
  @CasePathable
  enum FocusField: Equatable, Hashable {
    case name
  }
  
  private enum AddStepID: Hashable { case timer }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  var body: some Reducer<StepSectionReducer.State, StepSectionReducer.Action> {
    BindingReducer()
    Reduce<StepSectionReducer.State, StepSectionReducer.Action> { state, action in
      switch action {
        case let .steps(.element(id: id, action: .delegate(action))):
        switch action  {
        case .deleteButtonTapped:
          state.steps.remove(id: id)
          return .none
          
        case let .insertButtonTapped(aboveBelow):
          // TODO: Focus is not working properly. It cant seem to figure diff b/w .name and .description
          guard let i = state.steps.index(id: id) else { return .none }
          state.steps[i].focusedField = nil
          let newStep = StepReducer.State(
            step: .init(id: .init(rawValue: uuid())),
            focusedField: .description
          )
          state.steps.insert(newStep, at: aboveBelow == .above ? i : i + 1)
          return .none
        }
        
      case let .stepSectionNameEdited(newName):
        let oldName = state.stepSection.name
        if oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        if !oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          state.stepSection.name = ""
          return .none
        }
        let didEnter = DidEnter.didEnter(oldName, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.stepSection.name = newName
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if !state.steps.isEmpty { return .none }
          else {
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            /// This effect is also debounced to prevent multi additons as this action may be called from the a TextField
            /// which always emits twice when interacted with, which is a SwiftUI behavior:
            return .run { send in
              try await self.clock.sleep(for: .microseconds(10))
              await send(.addStep, animation: .default)
            }
            .cancellable(id: AddStepID.timer, cancelInFlight: true)
          }
        }
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
        
        
      case .addStep:
        state.steps.append(StepReducer.State(
          step: .init(id: .init(rawValue: uuid())),
          focusedField: .description
        ))
        return .none
        
      case .stepSectionUpdate:
        state.stepSection.steps = state.steps.map(\.step)
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          state.focusedField = nil
        }
        return .none
        
      case .delegate, .binding, .steps:
        return .none
      }
    }
    .forEach(\.steps, action: \.steps, element: StepReducer.init)
  }
}
