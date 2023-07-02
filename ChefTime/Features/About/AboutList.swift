import SwiftUI
import ComposableArchitecture

// TODO: Section deletion has no animation
// TODO: Section addition has no animation
// TODO: ContextMenu Previews need a look
// TODO: Make sure all expansions are matching what you want for the app
// TODO: Make TextField view with reducer to remove redundant code, maybe even possible for disclosure group...?
// MARK: - AboutListView
struct AboutListView: View {
  let store: StoreOf<AboutListReducer>
  @FocusState private var focusedField: AboutListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.aboutSections,
          action: AboutListReducer.Action.aboutSection
        )) { childStore in
          AboutSection(store: childStore)
            .contentShape(Rectangle())
            .focused($focusedField, equals: .row(ViewStore(childStore).id))
            .accentColor(.accentColor)
          
          if ViewStore(childStore).isExpanded {
            Rectangle()
              .fill(.clear)
              .frame(height: 5)
          }
          
          if !ViewStore(childStore).isExpanded {
            Divider()
          }
        }
      }
      label : {
        Text("About")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        Spacer()
      }
      .accentColor(.primary)
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
      .disclosureGroupStyle(CustomDisclosureGroupStyle()) // TODO: Make sure this is standardized!
    }
  }
}

// MARK: - AboutListReducer
struct AboutListReducer: ReducerProtocol {
  struct State: Equatable {
    var aboutSections: IdentifiedArrayOf<AboutSectionReducer.State>
    var isExpanded: Bool
    @BindingState var focusedField: FocusField? = nil
    
    init(
      recipe: Recipe,
      isExpanded: Bool,
      childrenIsExpanded: Bool
    ) {
      self.aboutSections = .init(uniqueElements: recipe.aboutSections.map {
        AboutSectionReducer.State(
          id: .init(),
          aboutSection: $0,
          isExpanded: isExpanded
        )
      })
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case aboutSection(AboutSectionReducer.State.ID, AboutSectionReducer.Action)
    case isExpandedButtonToggled
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .aboutSection(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .deleteSectionButtonTapped:
            state.aboutSections.remove(id: id)
            return .none
            
          case let .insertSection(aboveBelow):
            guard let i = state.aboutSections.index(id: id)
            else { return .none }
            let newSection = AboutSectionReducer.State(
              id: .init(),
              aboutSection: .init(id: .init(), name: "", description: ""), // TODO: Make sure all these inits matchup even lie ingredients
              isExpanded: true,
              focusedField: .name
            )
            switch aboveBelow {
            case .above: state.aboutSections.insert(newSection, at: i)
            case .below: state.aboutSections.insert(newSection, at: i + 1)
            }
            //            state.focusedField = .row(newSection.id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case .delegate, .binding:
        return .none
        
      }
    }
    .forEach(\.aboutSections, action: /Action.aboutSection) {
      AboutSectionReducer()
    }
  }
}

// MARK: - DelegateAction
extension AboutListReducer {
  enum DelegateAction {
    case sectionNavigationAreaTapped
  }
}

// MARK: - FocusField
extension AboutListReducer {
  enum FocusField: Equatable, Hashable {
    case row(AboutSectionReducer.State.ID)
  }
}

// MARK: - Previews
struct AboutList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        AboutListView(store: .init(
          initialState: .init(
            recipe: Recipe.longMock,
            isExpanded: true,
            childrenIsExpanded: true
          ),
          reducer: AboutListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
