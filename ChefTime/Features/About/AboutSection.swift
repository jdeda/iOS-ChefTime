import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// MARK: - View
struct AboutSection: View {
  let store: StoreOf<AboutSectionReducer>
  @FocusState private var focusedField: AboutSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        TextField(
          "...",
          text: viewStore.binding(
            get: \.aboutSection.description,
            send: { .aboutSectionDescriptionEdited($0) }
          ),
          axis: .vertical
        )
        .focused($focusedField, equals: .description)
        .accentColor(.accentColor)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .toolbar {
          if viewStore.focusedField == .description {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button {
                viewStore.send(.keyboardDoneButtonTapped)
              } label: {
                Text("done")
              }
            }
          }
        }
      } label: {
        TextField(
          "Untitled About Section",
          text: viewStore.binding(
            get: \.aboutSection.name,
            send: { .aboutSectionNameEdited($0) }
          ),
          axis: .vertical
        )
        .focused($focusedField, equals: .name)
        .textSubtitleStyle()
        .toolbar {
          if viewStore.focusedField == .name {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button {
                viewStore.send(.keyboardDoneButtonTapped)
              } label: {
                Text("done")
              }
            }
          }
        }
      }
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
      .contextMenu {
        Button {
          viewStore.send(.delegate(.insertSection(.above)), animation: .default)
        } label: {
          Text("Insert Section Above")
        }
        Button {
          viewStore.send(.delegate(.insertSection(.below)), animation: .default)
        } label: {
          Text("Insert Section Below")
        }
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      } preview: {
        AboutSectionContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

// MARK: - Reducer
struct AboutSectionReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var aboutSection: Recipe.AboutSection
    var isExpanded: Bool
    @BindingState var focusedField: FocusField?
    
    init(
      id: ID,
      aboutSection: Recipe.AboutSection,
      isExpanded: Bool,
      focusedField: FocusField? = nil
    ) {
      self.id = id
      self.aboutSection = aboutSection
      self.isExpanded = isExpanded
      self.focusedField = focusedField
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case isExpandedButtonToggled
    case aboutSectionNameEdited(String)
    case aboutSectionDescriptionEdited(String)
    case keyboardDoneButtonTapped
    case delegate(DelegateAction)
  }
    
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        state.focusedField = nil
        return .none
        
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
        
      case let .aboutSectionDescriptionEdited(newDescription):
        state.aboutSection.description = newDescription
        return .none
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
        
      case .delegate, .binding:
        return .none
      }
    }
    ._printChanges()
  }
}

// MARK: - DelegateAction
extension AboutSectionReducer {
  enum DelegateAction: Equatable {
    case deleteSectionButtonTapped
    case insertSection(AboveBelow)
  }
}

// MARK: - FocusField
extension AboutSectionReducer {
  enum FocusField: Equatable, Hashable {
    case name
    case description
  }
}


// MARK: - AboutSectionContextMenuPreview
private struct AboutSectionContextMenuPreview: View {
  let state: AboutSectionReducer.State
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      Text(!state.aboutSection.description.isEmpty ? state.aboutSection.description : "...")
        .lineLimit(4)
        .autocapitalization(.none)
        .autocorrectionDisabled()
    } label: {
      Text(!state.aboutSection.name.isEmpty ? state.aboutSection.name : "...")
        .lineLimit(2)
        .textSubtitleStyle()
    }
    .accentColor(.primary)
  }
}

// MARK: - Previews
struct AboutSection_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        AboutSection(store: .init(
          initialState: .init(
            id: .init(),
            aboutSection: Recipe.longMock.aboutSections.first!,
            isExpanded: true,
            focusedField: nil
          ),
          reducer: AboutSectionReducer.init
        ))
        .padding()
      }
    }
    
    NavigationStack {
      ScrollView {
        AboutSection(store: .init(
          initialState: .init(
            id: .init(),
            aboutSection: .init(id: .init(), name: "", description: ""),
            isExpanded: true,
            focusedField: nil
          ),
          reducer: AboutSectionReducer.init
        ))
        .padding()
      }
    }
  }
}
