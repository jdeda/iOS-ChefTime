import SwiftUI
import ComposableArchitecture

// TODO: For every feature deleagte,pleas euse a casepath, plerase dop it on all of them


// MARK: - StepListView
struct StepListView: View {
  let store: StoreOf<StepListReducer>
  @FocusState private var focusedField: StepListReducer.FocusField?
  // TODO: If they h ave a section with an empty name and content and click done just delete it...

  var body: some View {
    WithViewStore(store) { viewStore in
      if viewStore.stepSections.isEmpty {
        VStack {
          HStack {
            Text("Steps")
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
        DisclosureGroup(isExpanded: viewStore.binding(
          get: { $0.isExpanded },
          send: { _ in .isExpandedButtonToggled }
        )) {
          ForEachStore(store.scope(
            state: \.stepSections,
            action: StepListReducer.Action.stepSection
          )) { childStore in
            StepSection(store: childStore)
              .contentShape(Rectangle())
              .focused($focusedField, equals: .row(ViewStore(childStore).id))
              .accentColor(.accentColor)
            Divider()
              .padding(.bottom, 5)
          }
        }
        label : {
          Text("Steps")
            .textTitleStyle()
          Spacer()
        }
        .accentColor(.primary)
        .synchronize(viewStore.binding(\.$focusedField), $focusedField)
        .disclosureGroupStyle(CustomDisclosureGroupStyle()) // TODO: Make sure this is standardized!
      }
    }
  }
}

// MARK: - StepListReducer
struct StepListReducer: ReducerProtocol {
  struct State: Equatable {
    var stepSections: IdentifiedArrayOf<StepSectionReducer.State>
    var isExpanded: Bool
    @BindingState var focusedField: FocusField? = nil
  }

  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case stepSection(StepSectionReducer.State.ID, StepSectionReducer.Action)
    case isExpandedButtonToggled
    case addSectionButtonTapped
  }

  @Dependency(\.uuid) var uuid

  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .stepSection(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .deleteSectionButtonTapped:
            if case .row = state.focusedField {
              state.focusedField = nil
            }
            state.stepSections.remove(id: id)
            return .none

          case let .insertSection(aboveBelow):
            // TODO: Focus is not working properly. It cant seem to figure diff b/w .name and .description
            guard let i = state.stepSections.index(id: id) else { return .none }
            state.stepSections[i].focusedField = nil
              let newSection = StepSectionReducer.State(
                id: .init(rawValue: uuid()),
                name: "",
                steps: [],
                isExpanded: true,
                focusedField: .name // TODO: Which value?
              )
            state.stepSections.insert(newSection, at: aboveBelow == .above ? i : i + 1)
            state.focusedField = .row(newSection.id)
            return .none
          }
        default:
          return .none
        }

      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        state.focusedField = nil
        state.stepSections.ids.forEach { id1 in
          state.stepSections[id: id1]?.focusedField = nil
        }
        return .none

      case .addSectionButtonTapped:
        guard state.stepSections.isEmpty else { return .none }
          let s = StepSectionReducer.State(
            id: .init(rawValue: uuid()),
            name: "",
            steps: [],
            isExpanded: true,
            focusedField: nil
          )
        state.stepSections.append(s)
        state.focusedField = .row(s.id)
        return .none

      case .binding:
        return .none

      }
    }
    .forEach(\.stepSections, action: /Action.stepSection) {
      StepSectionReducer()
    }
  }
}

// MARK: - FocusField
extension StepListReducer {
  enum FocusField: Equatable, Hashable {
    case row(StepSectionReducer.State.ID)
  }
}

// MARK: - Previews
struct StepList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepListView(store: .init(
            initialState: .init(
                stepSections: .init(uniqueElements: Recipe.longMock.stepSections.map({ section in
                    .init(
                        id: .init(),
                        name: section.name,
                        steps: .init(uniqueElements: section.steps.map({ step in
                            .init(id: .init(), step: step, focusedField: nil)
                        })),
                        isExpanded: true,
                        focusedField: nil
                    )
                })),
                isExpanded: true,
                focusedField: nil
            ),
          reducer: StepListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
