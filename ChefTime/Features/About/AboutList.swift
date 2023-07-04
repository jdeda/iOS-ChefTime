import SwiftUI
import ComposableArchitecture

// MARK: - AboutListView
struct AboutListView: View {
  let store: StoreOf<AboutListReducer>
  @FocusState private var focusedField: AboutListReducer.FocusField?
  // TODO: If they have a section with an empty name and content and click done just delete it...
  
  var body: some View {
    WithViewStore(store) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        if viewStore.aboutSections.isEmpty {
          HStack {
            TextField(
              "Untitled About Section",
              text: .constant(""),
              axis: .vertical
            )
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .accentColor(.accentColor)
            .frame(alignment: .leading)
            .multilineTextAlignment(.leading)
            .lineLimit(.max)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            Spacer()
            Image(systemName: "plus")
          }
          .foregroundColor(.secondary)
          .onTapGesture {
            viewStore.send(.addSectionButtonTapped, animation: .default)
          }
        }
        else {
          ForEachStore(store.scope(
            state: \.aboutSections,
            action: AboutListReducer.Action.aboutSection
          )) { childStore in
            AboutSection(store: childStore)
              .contentShape(Rectangle())
              .focused($focusedField, equals: .row(ViewStore(childStore).id))
              .accentColor(.accentColor)
            
            if ViewStore(childStore).isExpanded {
              Rectangle() // This serves a spacer()
                .fill(.clear)
                .frame(height: 5)
            }
            
            if !ViewStore(childStore).isExpanded {
              Divider()
            }
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
      @Dependency(\.uuid) var uuid
      
      self.aboutSections = .init(uniqueElements: recipe.aboutSections.map {
        AboutSectionReducer.State(
          id: .init(rawValue: uuid()),
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
    case addSectionButtonTapped
    case delegate(DelegateAction)
  }
  
  @Dependency(\.uuid) var uuid
  
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
            // TODO: Focus is not working properly. It cant seem to figure diff b/w .name and .description
            guard let i = state.aboutSections.index(id: id) else { return .none }
            let newSection = AboutSectionReducer.State(
              id: .init(rawValue: uuid()),
              aboutSection: .init(id: .init(rawValue: uuid()), name: "", description: ""),
              isExpanded: true,
              focusedField: .name
            )
            state.aboutSections.insert(newSection, at: aboveBelow == .above ? i : i + 1)
            state.focusedField = .row(newSection.id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        state.focusedField = nil
        state.aboutSections.ids.forEach { id1 in
          state.aboutSections[id: id1]?.focusedField = nil
        }
        return .none
        
      case .addSectionButtonTapped:
        let s = AboutSectionReducer.State.init(
          id: .init(rawValue: uuid()),
          aboutSection: .init(id: .init(rawValue: uuid()), name: "", description: ""),
          isExpanded: true,
          focusedField: .name
        )
        state.aboutSections.append(s)
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
            recipe: Recipe.empty,
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
