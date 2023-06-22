import SwiftUI
import ComposableArchitecture
import Tagged

// MARK: - View
struct AboutPreviewListView: View {
  let store: StoreOf<AboutPreviewListReducer>
  
  struct ViewState: Equatable {
    var sections: IdentifiedArrayOf<AboutPreviewReducer.State>
    var isExpanded: Bool
    
    init(_ state: AboutPreviewListReducer.State) {
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
          action: AboutPreviewListReducer.Action.section
        )) { childStore in
          AboutPreview(store: childStore)
          Divider()
        }
      } label: {
        Text("About")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .accentColor(.primary)
    }
  }
}

// MARK: - Reducer
struct AboutPreviewListReducer: ReducerProtocol {
  struct State: Equatable {
    var sections: IdentifiedArrayOf<AboutPreviewReducer.State>
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
    case section(AboutPreviewReducer.State.ID, AboutPreviewReducer.Action)
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
      AboutPreviewReducer()
    }
  }
}

// MARK: - Preview
struct AboutPreviewListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        AboutPreviewListView(store: .init(
          initialState: .init(recipe: .longMock, isExpanded: true, childrenIsExpanded: true),
          reducer: AboutPreviewListReducer.init
        ))
      }
      .padding()
    }
  }
}

struct AboutPreview: View {
  let store: StoreOf<AboutPreviewReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(\.$isExpanded)) {
        TextField(
          "...",
          text: .constant(viewStore.section.description),
          axis: .vertical
        )
        .disabled(true)
        .accentColor(.accentColor)
      } label: {
        TextField(
          "Untitled Section",
          text: .constant(viewStore.section.name),
          axis: .vertical
        )
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
        .disabled(true)
      }
      .accentColor(.primary)
    }
  }
}
