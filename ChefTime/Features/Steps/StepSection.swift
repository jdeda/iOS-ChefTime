import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: - Bug - if focused on a row, then collapse, then click a row again, dupe buttons appear...
// but sometimes if you tap another row, the dupe goes away, this does not work all the time
// this is all happening probably because we didn't nil out the focus state

// MARK: - View
struct StepSection: View {
  let store: StoreOf<StepSectionReducer>
  @FocusState private var focusedField: StepSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.steps,
          action: StepSectionReducer.Action.step
        )) { childStore in
          // TODO: Move this into reducer and test.
          let id = ViewStore(childStore).id
          let index = viewStore.steps.index(id:id) ?? 0
          StepView(store: childStore, index: index)
            .accentColor(.accentColor)
          if let lastId = viewStore.steps.last?.id, lastId != id {
            Divider()
          }
        }
      } label: {
        TextField(
          "Untitled About Section",
          text: viewStore.binding(
            get: \.name,
            send: { .stepSectionNameEdited($0) }
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
        StepSectionContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

// MARK: - Reducer
struct StepSectionReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var steps: IdentifiedArrayOf<StepReducer.State>
    var isExpanded: Bool
    @BindingState var focusedField: FocusField?
  }
  
  enum Action: Equatable, BindableAction {
    case step(StepReducer.State.ID, StepReducer.Action)
    case binding(BindingAction<State>)
    case isExpandedButtonToggled
    case stepSectionNameEdited(String)
    case addStep
    case keyboardDoneButtonTapped
    case delegate(DelegateAction)
  }
  
  private enum AddStepID: Hashable { case timer }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .step(id, action):
        let action = (/StepReducer.Action.delegate).extract(from: action)
        switch action  {
        case .deleteButtonTapped:
          state.steps.remove(id: id)
          return .none

        case let .insertButtonTapped(aboveBelow):
          // TODO: Focus is not working properly. It cant seem to figure diff b/w .name and .description
          guard let i = state.steps.index(id: id) else { return .none }
          state.steps[i].focusedField = nil
          let newStep = StepReducer.State(
            id: .init(rawValue: uuid()),
            step: .init(id: .init(rawValue: uuid()), description: ""),
            focusedField: .description
          )
          state.steps.insert(newStep, at: aboveBelow == .above ? i : i + 1)
          return .none
          
        case .none:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        state.focusedField = nil
        return .none
        
      case let .stepSectionNameEdited(newName):
        let oldName = state.name
        if oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        if !oldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          state.name = ""
          return .none
        }
        let didEnter = DidEnter.didEnter(oldName, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.name = newName
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if !state.steps.isEmpty { return .none }
          else {
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            /// This effect is also debounced to prevent multi additons as this action may be called from the a TextField
            /// which always emits twice when interacted with, which is a SwiftUI behavior:
            return .run { send in
              try await self.clock.sleep(for: .microseconds(10))
              await send(.addStep, animation: .default)
            }
            .cancellable(id: AddStepID.timer, cancelInFlight: true)
          }
        }
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
        
        
      case .addStep:
        state.steps.append(StepReducer.State(
          id: .init(rawValue: uuid()),
          step: .init(id: .init(rawValue: uuid()), description: ""),
          focusedField: .description
        ))
        return .none
        
      case .delegate, .binding:
        return .none
      }
    }
    .forEach(\.steps, action: /Action.step) {
      StepReducer()
    }
  }
}

// MARK: - DelegateAction
extension StepSectionReducer {
  enum DelegateAction: Equatable {
    case deleteSectionButtonTapped
    case insertSection(AboveBelow)
  }
}

// MARK: - FocusField
extension StepSectionReducer {
  enum FocusField: Equatable, Hashable {
    case name
  }
}


// MARK: - StepSectionContextMenuPreview
private struct StepSectionContextMenuPreview: View {
  let state: StepSectionReducer.State
  let maxW = UIScreen.main.bounds.width * 0.95
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      ForEach(state.steps.prefix(4)) { step in
        StepContextMenuPreview(state: step)
        Divider() // TODO: Dont render last divier
      }
    } label: {
      TextField("Untitled About Section", text: .constant(state.name))
        .textSubtitleStyle()
        .lineLimit(2)
        .disabled(true)
    }
    .accentColor(.primary)
  }
}

// MARK: - Previews
struct StepSection_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepSection(store: .init(
          initialState: .init(
            id: .init(),
            name: Recipe.longMock.stepSections.first!.name,
            steps: .init(uniqueElements: Recipe.longMock.stepSections.first!.steps.map({
              .init(id: .init(), step: $0)
            })),
            isExpanded: true,
            focusedField: nil
          ),
          reducer: StepSectionReducer.init
        ))
        .padding()
      }
    }
  }
}
