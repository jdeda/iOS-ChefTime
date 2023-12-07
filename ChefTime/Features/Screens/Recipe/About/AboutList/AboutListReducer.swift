import ComposableArchitecture

/// 1. computed property, send a delegate action `aboutSectionsDidChange`, and the parent just reads the computed property
/// 2. normal property, onChange, send a delegate action `aboutSectionsDidChange`
///
/// X. computed property, onChange, send a delegate action `aboutSectionsDidChange`, and the parent just reads the computed property
struct AboutListReducer: Reducer {
  struct State: Equatable {
    var aboutSections: IdentifiedArrayOf<AboutSectionReducer.State> = []
    
    @BindingState var isExpanded: Bool = true
    @BindingState var focusedField: FocusField? = nil
    
    init(recipeSections: IdentifiedArrayOf<Recipe.AboutSection>) {
      self.aboutSections = recipeSections.map{ .init(aboutSection: $0) }
    }
    
    var recipeSections: IdentifiedArrayOf<Recipe.AboutSection> {
      aboutSections.map(\.aboutSection)
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case aboutSections(AboutSectionReducer.State.ID, AboutSectionReducer.Action)
    case addSectionButtonTapped
  }
  
  
  
  enum FocusField: Equatable, Hashable {
    case row(AboutSectionReducer.State.ID)
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .aboutSections(id, .delegate(action)):
        switch action {
        case .deleteSectionButtonTapped:
          if case .row = state.focusedField {
            state.focusedField = nil
          }
          state.aboutSections.remove(id: id)
          return .none
          
        case let .insertSection(aboveBelow):
          // TODO: Focus is not working properly. It cant seem to figure diff b/w .name and .description
          guard let i = state.aboutSections.index(id: id) else { return .none }
          state.aboutSections[i].focusedField = nil
          
          let newSection_: Recipe.AboutSection =  .init(id: .init(rawValue: uuid()), name: "", description: "")
          let newSection = AboutSectionReducer.State(aboutSection: newSection_, focusedField: .name)
          
          state.aboutSections.insert(newSection, at: aboveBelow == .above ? i : i + 1)
          state.focusedField = .row(newSection.id)
          return .none
        }
        
      case .addSectionButtonTapped:
        guard state.aboutSections.isEmpty else { return .none }
        
        let newSection_: Recipe.AboutSection =  .init(id: .init(rawValue: uuid()), name: "", description: "")
        let newSection = AboutSectionReducer.State(aboutSection: newSection_, focusedField: .name)
        
        state.aboutSections.append(newSection)
        state.focusedField = .row(newSection.id)
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          state.focusedField = nil
          state.aboutSections.ids.forEach { id1 in
            state.aboutSections[id: id1]?.focusedField = nil
          }
        }
        return .none
        
      case .binding, .aboutSections:
        return .none
      }
    }
    .forEach(\.aboutSections, action: /AboutListReducer.Action.aboutSections) {
      AboutSectionReducer()
    }
  }
}
