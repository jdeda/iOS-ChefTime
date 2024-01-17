import ComposableArchitecture

struct StepListReducer: Reducer {
  struct State: Equatable {
    var stepSections: IdentifiedArrayOf<StepSectionReducer.State> = [] {
      didSet {
        if self.stepSections.count == 1 &&
            self.stepSections.first!.steps.isEmpty {
          self.stepSections = []
        }
      }
    }
    @BindingState var isExpanded: Bool = true
    @BindingState var isHidingImages: Bool = false
    @BindingState var focusedField: FocusField? = nil
    
    init(recipeSections: IdentifiedArrayOf<Recipe.StepSection>) {
      self.stepSections = recipeSections.map { .init(stepSection: $0) }
    }
    
    var recipeSections: IdentifiedArrayOf<Recipe.StepSection> {
      self.stepSections.map(\.stepSection)
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case stepSections(StepSectionReducer.State.ID, StepSectionReducer.Action)
    case addSectionButtonTapped
  }
  
  
  enum FocusField: Equatable, Hashable {
    case row(StepSectionReducer.State.ID)
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .stepSections(id, .delegate(action)):
        switch action {
        case .deleteSectionButtonTapped:
          if case .row = state.focusedField {
            state.focusedField = nil
          }
          state.stepSections.remove(id: id)
          return .none
          
        case let .insertSection(aboveBelow):
          // TODO: Focus is not working properly. It cant seem to figure diff b/w .name and .description
          guard let i = state.stepSections.index(id: id) else { return .none }
          state.stepSections[i].focusedField = nil
          let newSection = StepSectionReducer.State(
            stepSection: .init(id: .init(rawValue: uuid())),
            focusedField: .name
          )
          state.stepSections.insert(newSection, at: aboveBelow == .above ? i : i + 1)
          state.focusedField = .row(newSection.id)
          return .none
        }
        
      case .addSectionButtonTapped:
        guard state.stepSections.isEmpty else { return .none }
        let s = StepSectionReducer.State(stepSection: .init(id: .init(rawValue: uuid())))
        state.stepSections.append(s)
        state.focusedField = .row(s.id)
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          state.focusedField = nil
          state.stepSections.ids.forEach { id1 in
            state.stepSections[id: id1]?.focusedField = nil
          }
        }
        return .none
        
      case .binding, .stepSections:
        return .none
      }
    }
    .forEach(\.stepSections, action: /StepListReducer.Action.stepSections) {
      StepSectionReducer()
    }
  }
}
