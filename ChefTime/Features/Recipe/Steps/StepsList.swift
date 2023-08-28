import SwiftUI
import ComposableArchitecture

// MARK: - StepListView
struct StepListView: View {
  let store: StoreOf<StepListReducer>
  @FocusState private var focusedField: StepListReducer.FocusField?
  @Environment(\.isHidingStepImages) var isHidingStepImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
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
          DisclosureGroup(isExpanded: viewStore.$isExpanded) {
            Toggle(isOn: .constant(viewStore.isHidingStepImages)) {
              Text("Hide Images")
                .textSubtitleStyle()
            } // onTapGesture because regular Toggle just breaks and you can't click it.
            .onTapGesture {
              viewStore.send(.hideImagesToggled)
            }
            
            ForEachStore(store.scope(
              state: \.stepSections,
              action: StepListReducer.Action.stepSection
            )) { childStore in
              StepSection(store: childStore)
                .contentShape(Rectangle())
                .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
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
          .disclosureGroupStyle(CustomDisclosureGroupStyle())
        }
      }
      .synchronize(viewStore.$focusedField, $focusedField)
      .environment(\.isHidingStepImages, viewStore.isHidingStepImages)
    }
  }
}

// MARK: - StepListReducer
struct StepListReducer: Reducer {
  struct State: Equatable {
    var stepSections: IdentifiedArrayOf<StepSectionReducer.State>
    @BindingState var isExpanded: Bool
    @BindingState var isHidingStepImages: Bool = false
    @BindingState var focusedField: FocusField? = nil
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case stepSection(StepSectionReducer.State.ID, StepSectionReducer.Action)
    case hideImagesToggled
    case addSectionButtonTapped
    case hideImages
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  private enum HideImagesToggledID: Hashable { case timer }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .stepSection(id, .delegate(action)):
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
              focusedField: .name
            )
            state.stepSections.insert(newSection, at: aboveBelow == .above ? i : i + 1)
            state.focusedField = .row(newSection.id)
            return .none
          }
        
      case .hideImagesToggled:
        return .run { send in
          try await self.clock.sleep(for: .milliseconds(250))
          await send(.hideImages)
        }
        .cancellable(id: HideImagesToggledID.timer, cancelInFlight: true)
        
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
        
      case .hideImages:
        state.isHidingStepImages.toggle()
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          state.focusedField = nil
          state.stepSections.ids.forEach { id1 in
            state.stepSections[id: id1]?.focusedField = nil
          }
        }
        return .none
        
      case .binding, .stepSection:
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
          reducer: StepListReducer.init
        ))
        .padding()
      }
    }
  }
}
