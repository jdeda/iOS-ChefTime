import SwiftUI
import ComposableArchitecture

// MARK: - AboutListView
struct AboutListView: View {
  let store: StoreOf<AboutListReducer>
  @FocusState private var focusedField: AboutListReducer.FocusField?

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      if viewStore.aboutSections.isEmpty {
        VStack {
          HStack {
            Text("About")
              .textTitleStyle()
            Spacer()
          }
          HStack {
            TextField(
              "Untitled About Section",
              text: .constant(""),
              axis: .vertical
            )
            .textSubtitleStyle()
            Spacer()
            Image(systemName: "plus")
          }
          .foregroundColor(.secondary)
          .onTapGesture {
            viewStore.send(.addSectionButtonTapped, animation: .default)
          }
        }
      }
      else {
        DisclosureGroup(isExpanded: viewStore.$isExpanded.animation(.easeIn(duration: 2.5))) {
//        DisclosureGroup(isExpanded: viewStore.binding(
//          get: { $0.isExpanded },
//          send: { _ in .isExpandedButtonToggled } // .send(.isExpandedButtonToggled, animation: .default) }
//        ).animation(.easeIn(duration: 2.5))) {
          ForEachStore(store.scope(
            state: \.aboutSections,
            action: AboutListReducer.Action.aboutSection
          )) { childStore in
            AboutSection(store: childStore)
              .contentShape(Rectangle())
              .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
              .accentColor(.accentColor)
            Divider()
              .padding([.vertical], 5)
          }
        }
        label : {
          Text("About")
            .textTitleStyle()
          Spacer()
        }
        .accentColor(.primary)
        .synchronize(viewStore.$focusedField, $focusedField)
        .disclosureGroupStyle(CustomDisclosureGroupStyle())
      }
    }
  }
}

// MARK: - AboutListReducer
struct AboutListReducer: Reducer {
  struct State: Equatable {
    var aboutSections: IdentifiedArrayOf<AboutSectionReducer.State>
    @BindingState var isExpanded: Bool
    @BindingState var focusedField: FocusField? = nil
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case aboutSection(AboutSectionReducer.State.ID, AboutSectionReducer.Action)
    case isExpandedButtonToggled
    case addSectionButtonTapped
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .aboutSection(id, action):
        switch action {
        case let .delegate(action):
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
        guard state.aboutSections.isEmpty else { return .none }
        let s = AboutSectionReducer.State.init(
          id: .init(rawValue: uuid()),
          aboutSection: .init(id: .init(rawValue: uuid()), name: "", description: ""),
          isExpanded: true,
          focusedField: .name
        )
        state.aboutSections.append(s)
        state.focusedField = .row(s.id)
        return .none
        
      case .binding(\.$isExpanded):
        state.focusedField = nil
        state.aboutSections.ids.forEach { id1 in
          state.aboutSections[id: id1]?.focusedField = nil
        }
        return .none
        
      case .binding:
        return .none
        
      }
    }
    .forEach(\.aboutSections, action: /Action.aboutSection) {
      AboutSectionReducer()
    }
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
            aboutSections: .init(uniqueElements: Recipe.longMock.aboutSections.map({
              .init(id: .init(), aboutSection: $0, isExpanded: true)
            })),
            isExpanded: true
          ),
          reducer: AboutListReducer.init
        ))
        .padding()
      }
    }
  }
}
