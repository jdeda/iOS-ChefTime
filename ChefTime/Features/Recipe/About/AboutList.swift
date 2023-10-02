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
        DisclosureGroup(isExpanded: viewStore.$isExpanded) {
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
    // we want to power using this
    var aboutSections: IdentifiedArrayOf<AboutSectionReducer.State> = []
    
    @BindingState var isExpanded: Bool = true
    @BindingState var focusedField: FocusField? = nil
    
    init(recipeSections: IdentifiedArrayOf<Recipe.AboutSection>) {
      self.aboutSections = recipeSections.map(AboutSectionReducer.State.init(aboutSection:))
    }
    
    var recipeSections: IdentifiedArrayOf<Recipe.AboutSection> {
      aboutSections.map(\.aboutSection)
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case aboutSection(AboutSectionReducer.State.ID, AboutSectionReducer.Action)
    case addSectionButtonTapped
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .aboutSection(id, .delegate(action)):
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
          let newSection = AboutSectionReducer.State(aboutSection: newSection_)
          
          state.aboutSections.insert(newSection, at: aboveBelow == .above ? i : i + 1)
          state.focusedField = .row(newSection.id)
          return .none
        }
        
      case .addSectionButtonTapped:
        guard state.aboutSections.isEmpty else { return .none }
        
        let newSection_: Recipe.AboutSection =  .init(id: .init(rawValue: uuid()), name: "", description: "")
        let newSection = AboutSectionReducer.State(aboutSection: newSection_)

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
        
      case .binding, .aboutSection:
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
            recipeSections: Recipe.longMock.aboutSections
          ),
          reducer: AboutListReducer.init
        ))
        .padding()
      }
    }
  }
}

extension IdentifiedArrayOf where Element: Identifiable {
  func map<B>(_ transform: (Element) -> B) -> IdentifiedArrayOf<B> where B: Identifiable {
    .init(uniqueElements: self.elements.map(transform))
  }
}
