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
    case aboutSectionNameSet(String)
    case aboutSectionDescriptionEdited(String)
    case aboutSectionDescriptionSet(String)
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
  
  @Dependency(\.continuousClock) var clock

  enum NameEditedID: Hashable { case debounce }
  enum DescriptionEditedID: Hashable { case debounce }
    
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .aboutSectionNameEdited(newName):
        return .run { send in
          try await self.clock.sleep(for: .milliseconds(250))
          await send(.aboutSectionNameSet(newName))
        }
        .cancellable(id: NameEditedID.debounce, cancelInFlight: true)
        
      case let .aboutSectionNameSet(newName):
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
        
      case let .aboutSectionDescriptionEdited(newDescription):
        return .run { send in
          try await self.clock.sleep(for: .milliseconds(250))
          await send(.aboutSectionDescriptionSet(newDescription))
        }
        .cancellable(id: DescriptionEditedID.debounce, cancelInFlight: true)

      case let .aboutSectionDescriptionSet(newDescription):
        state.aboutSection.description = newDescription
        return .none
        
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
