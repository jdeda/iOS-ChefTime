import SwiftUI
import ComposableArchitecture

// MARK: - View
struct AboutListView: View {
  let store: StoreOf<AboutListReducer>
  
  struct ViewState: Equatable {
    var sections: IdentifiedArrayOf<AboutReducer.State>
    var isExpanded: Bool
    
    init(_ state: AboutListReducer.State) {
      self.sections = state.sections
      self.isExpanded = state.isExpanded
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: \.isExpanded,
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.sections,
          action: AboutListReducer.Action.section
        )) { childStore in
          AboutView(store: childStore)
          Divider()
        }
      } label: {
          Text("About")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
      }
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
    }
  }
}

// MARK: - Reducer
struct AboutListReducer: ReducerProtocol {
  struct State: Equatable {
    var sections: IdentifiedArrayOf<AboutReducer.State>
    var isExpanded: Bool
    
    init(recipe: Recipe, isExpanded: Bool, childrenIsExpanded: Bool) {
      self.sections = .init(uniqueElements: recipe.aboutSections.map { section in
          .init(id: .init(), section: section, isExpanded: childrenIsExpanded)
      })
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable {
    case isExpandedButtonToggled
    case section(AboutReducer.State.ID, AboutReducer.Action)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .section(id, action):
        return .none
      }
    }
    .forEach(\.sections, action: /Action.section) {
      AboutReducer()
    }
  }
}

// MARK: - Preview
struct AboutListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        AboutListView(store: .init(
          initialState: .init(recipe: .longMock, isExpanded: true, childrenIsExpanded: true),
          reducer: AboutListReducer.init
        ))
      }
      .padding()
    }
  }
}
