import ComposableArchitecture

struct AboutSectionReducer: Reducer {
  struct State: Equatable, Identifiable {
    var id: Recipe.AboutSection.ID { aboutSection.id }
    @BindingState var aboutSection: Recipe.AboutSection
    @BindingState var isExpanded: Bool = true
    @BindingState var focusedField: FocusField? = nil
    
    init(aboutSection: Recipe.AboutSection, focusedField: FocusField? = nil) {
      self.aboutSection = aboutSection
      self.focusedField = focusedField
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case aboutSectionNameEdited(String)
    case keyboardDoneButtonTapped

    case delegate(DelegateAction)
    
    enum DelegateAction: Equatable {
      case deleteSectionButtonTapped
      case insertSection(AboveBelow)
    }
  }
  
  
  enum FocusField: Equatable, Hashable {
    case name
    case description
  }
    
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .aboutSectionNameEdited(newName):
        let oldName = state.aboutSection.name
        if oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        if !oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          state.aboutSection.name = ""
          return .none
        }
        let didEnter = DidEnter.didEnter(oldName, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.aboutSection.name = newName
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if !state.aboutSection.description.isEmpty { return .none }
          else {
            state.focusedField = .description
            return .none
          }
        }
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          state.focusedField = nil
        }
        return .none
        
      case .delegate, .binding:
        return .none
      }
    }
  }
}
