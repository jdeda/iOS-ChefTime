import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: Scale causes ugly refres

// TODO: - Bug - if focused on a row, then collapse, then click a row again, dupe buttons appear...
// but sometimes if you tap another row, the dupe goes away, this does not work all the time
// this is all happening probably because we didn't nil out the focus state

// TODO: Make sure all accent colors are lightened up

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
          .foregroundColor(.primary)
          .accentColor(.accentColor)
          .frame(alignment: .leading)
          .multilineTextAlignment(.leading)
          .lineLimit(.max)
          .autocapitalization(.none)
          .autocorrectionDisabled()
      } label: {
        // TODO: An alert might feel nicer here to restore the DisclosureGroup collapse UX.
        TextField(
          "Untitled About Section",
          text: viewStore.binding(
            get: \.aboutSection.name,
            send: { .aboutSectionNameEdited($0) }
          ),
          axis: .vertical
        )
        .focused($focusedField, equals: .name)
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
        .lineLimit(.max)
        .autocapitalization(.none)
        .autocorrectionDisabled()
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
    case delegate(DelegateAction)
  }
  
  @Dependency(\.continuousClock) var clock
  
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
        // TODO: Make this .trimmingWhiteCharacter thing an extension thats alot shorter as its used a lot:
        // myString.trimmedWhitespacesAndNewlines.isEmpty
        // myString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let didEnter = DidEnter.didEnter(oldName, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.aboutSection.name = newName
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .send(.delegate(.deleteSectionButtonTapped))
          }
          else {
            return .none
          }
        }
        
      case let .aboutSectionDescriptionEdited(newDescription):
        let oldDescription = state.aboutSection.description
        if oldDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        // TODO: Make this .trimmingWhiteCharacter thing an extension thats alot shorter as its used a lot:
        // myString.trimmedWhitespacesAndNewlines.isEmpty
        // myString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let didEnter = DidEnter.didEnter(oldDescription, newDescription)
        switch didEnter {
        case .didNotSatisfy:
          state.aboutSection.description = newDescription
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if oldDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .send(.delegate(.deleteSectionButtonTapped))
          }
          else {
            return .none
          }
        }
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
          .foregroundColor(.primary)
          .accentColor(.accentColor)
          .frame(alignment: .leading)
          .multilineTextAlignment(.leading)
          .lineLimit(4)
          .autocapitalization(.none)
          .autocorrectionDisabled()
      } label: {
        Text(!state.aboutSection.name.isEmpty ? state.aboutSection.name : "Untitled About Section")
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .autocapitalization(.none)
        .autocorrectionDisabled()
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
          reducer: AboutSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
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
          reducer: AboutSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
