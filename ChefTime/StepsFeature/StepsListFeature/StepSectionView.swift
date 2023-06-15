import SwiftUI
import ComposableArchitecture
import Tagged

struct StepSectionView: View {
  let store: StoreOf<StepSectionReducer>
  
  struct ViewState: Equatable {
    var name: String
    var steps: IdentifiedArrayOf<StepReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: StepSectionReducer.Destination.State?
    
    init(_ state: StepSectionReducer.State) {
      self.name = state.name
      self.steps = state.steps
      self.isExpanded = state.isExpanded
      self.destination = state.destination
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: \.isExpanded,
        send: { _ in .isExpandedButtonToggled }
      )) {
        Divider()
        ForEachStore(store.scope(
          state: \.steps,
          action: StepSectionReducer.Action.step
        )) { childStore in
          StepView(store: childStore)
          Divider()
        }
        .accentColor(.accentColor)
        
        AddStepView()
        //          .onTapGesture {
        //            viewStore.send(.addIngredientButtonTapped, animation: .default)
        //          }
      } label: {
        TextField(
          "Untitled Step Section",
          text: viewStore.binding(
            get: \.name,
            send: { .nameEdited($0) }
          ),
          axis: .vertical
        )
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
      }
      .accentColor(.primary)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .contextMenu(menuItems: {
        Button(role: .destructive) {
          // TODO: - Lots of lag. The context menu is laggy...
          viewStore.send(.deleteButtonTapped, animation: .default)
        } label: {
          Text("Delete")
        }
      }, preview: {
        StepSectionView(store: store)
          .padding()
      })
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
        state: /StepSectionReducer.Destination.State.alert,
        action: StepSectionReducer.Destination.Action.alert
      )
    }
  }
}

struct StepSectionReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var steps: IdentifiedArrayOf<StepReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: Destination.State?
    
    
    init(
      id: ID,
      stepSection: Recipe.StepSection,
      isExpanded: Bool,
      destination: Destination.State? = nil
    )  {
      self.id = id
      self.name = stepSection.name
      self.steps = .init(uniqueElements: stepSection.steps.enumerated().map { (index, step) in
          .init(
            id: .init(),
            stepNumber: index + 1,
            step: step
          )
      })
      self.isExpanded = isExpanded
      self.destination = destination
    }
  }
  
  enum Action: Equatable {
    case isExpandedButtonToggled
    case step(StepReducer.State.ID, StepReducer.Action)
    case nameEdited(String)
    case deleteButtonTapped
    case delegate(DelegateAction)
    case destination(PresentationAction<Destination.Action>)
  }
  
  enum DelegateAction: Equatable {
    case deleteButtonConfirmed
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .step(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .deleteButtonTapped:
            state.steps.remove(id: id)
            state.steps.ids.enumerated().forEach { (i, id) in
              state.steps[id: id]?.stepNumber = i + 1
            }
            return .none
          }
        default:
          return .none
        }
        
      case let .nameEdited(newName):
        state.name = newName
        return .none
        
      case .deleteButtonTapped:
        // TODO: Move this state elsewhere
        state.destination = .alert(.init(
          title: { TextState("Confirm Deletion")},
          actions: {
            .init(role: .destructive, action: .confirmSectionDeletion) {
              TextState("Confirm")
            }
          },
          message: {
            TextState("Are you sure you want to delete this section?")
          }
        ))
        return .none
        
      case .delegate:
        return .none
        
      case let .destination(action):
        switch action {
        case .presented(.alert(.confirmSectionDeletion)):
          return .send(.delegate(.deleteButtonConfirmed), animation: .default)
        case .dismiss:
          return .none
        }
      }
    }
  }
  
  struct Destination: ReducerProtocol {
    enum State: Equatable {
      case alert(AlertState<AlertAction>)
      
    }
    enum Action: Equatable {
      case alert(AlertAction)
    }
    var body: some ReducerProtocolOf<Self> {
      EmptyReducer()
    }
  }
  
  enum AlertAction: Equatable {
    case confirmSectionDeletion
  }
}

struct StepSectionView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepSectionView(store: .init(
          initialState: .init(
            id: .init(),
            stepSection: Recipe.mock.steps.first!,
            isExpanded: true
          ),
          reducer: StepSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}

struct AddStepView: View {
  var body: some View {
    HStack(alignment: .top) {
      Spacer()
      Image(systemName: "plus")
        .fontWeight(.medium)
        .padding([.top], 2)
    }
    .foregroundColor(.secondary)
    .accentColor(.accentColor)
  }
}
