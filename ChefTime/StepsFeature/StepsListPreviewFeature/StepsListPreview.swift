import SwiftUI
import ComposableArchitecture
import Tagged

struct StepsListPreview: View {
  let store: StoreOf<StepsListPreviewReducer>
  @State var isOn: Bool = false
  
  @State var isExpanded: Bool = true
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: \.isExpanded,
        send: { _ in .isExpandedButtonToggled }
      )) {
        Toggle("Hide Images", isOn: $isOn)
          .font(.title3)
          .fontWeight(.bold)
        
        ForEachStore(store.scope(
          state: \.sections,
          action: StepsListPreviewReducer.Action.section
        )) { childStore in
          StepSectionPreview(store: childStore)
        }
        
        HStack {
          Text(" ")
          Spacer()
          Image(systemName: "plus")
            .font(.caption)
            .fontWeight(.bold)
            .onTapGesture {
//              viewStore.send(.addIngredientSectionButtonTapped, animation: .default)
            }
        }
        .foregroundColor(.secondary)
        
        Divider()
      } label: {
        Text("Steps")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
    }
  }
}

struct StepsListPreviewReducer: ReducerProtocol {
  struct State: Equatable {
    var isExpanded: Bool
    var sections: IdentifiedArrayOf<StepSectionPreviewReducer.State>
    
    init(recipe: Recipe, isExpanded: Bool) {
      self.sections = .init(uniqueElements: recipe.steps.map { section in
          .init(
            id: .init(),
            stepSection: section,
            isExpanded: true
          )
      })
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable {
    case isExpandedButtonToggled
    case section(StepSectionPreviewReducer.State.ID, StepSectionPreviewReducer.Action)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .section(id, action):
        switch action {
        case let .delegate(action):
          return .none
        default:
          return .none
        }
      }
    }
    .forEach(\.sections, action: /Action.section) {
      StepSectionPreviewReducer()
    }
  }
}

struct StepsListPreview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepsListPreview(store: .init(
          initialState: .init(recipe: Recipe.mock, isExpanded: true),
          reducer: StepsListPreviewReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}

struct StepSectionPreview: View {
  let store: StoreOf<StepSectionPreviewReducer>
  
  struct ViewState: Equatable {
    var name: String
    var steps: IdentifiedArrayOf<StepPreviewReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: StepSectionPreviewReducer.Destination.State?
    
    init(_ state: StepSectionPreviewReducer.State) {
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
          action: StepSectionPreviewReducer.Action.step
        )) { childStore in
          StepPreview(store: childStore)
          Divider()
        }
        .accentColor(.accentColor)
        
        AddStepPreview()
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
        StepSectionPreview(store: store)
          .padding()
      })
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
        state: /StepSectionPreviewReducer.Destination.State.alert,
        action: StepSectionPreviewReducer.Destination.Action.alert
      )
    }
  }
}

struct StepSectionPreviewReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var steps: IdentifiedArrayOf<StepPreviewReducer.State>
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
    case step(StepPreviewReducer.State.ID, StepPreviewReducer.Action)
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

struct StepSectionPreview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepSectionPreview(store: .init(
          initialState: .init(
            id: .init(),
            stepSection: Recipe.mock.steps.first!,
            isExpanded: true
          ),
          reducer: StepSectionPreviewReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}

struct AddStepPreview: View {
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

struct StepPreview: View {
  let store: StoreOf<StepPreviewReducer>
  
  struct ViewState: Equatable {
    var step: Recipe.StepSection.Step
    var stepNumber: Int
    
    init(_ state: StepPreviewReducer.State) {
      self.step = state.step
      self.stepNumber = state.stepNumber
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      VStack(alignment: .leading) {
        Text("Step \(viewStore.stepNumber)")
          .fontWeight(.medium)
        TextField(
          "...",
          text: viewStore.binding(
            get: \.step.description,
            send: { .stepDescriptionEdited($0) }
          ),
          axis: .vertical
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        //        Image("burger_bun_01")
        //          .resizable()
        //          .scaledToFill()
        //          .clipShape(RoundedRectangle(cornerRadius: 10))
      }
      .contextMenu {
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
        
      }
    }
  }
}

struct StepPreviewReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var stepNumber: Int
    var step: Recipe.StepSection.Step
  }
  
  enum Action: Equatable {
    case stepDescriptionEdited(String)
    case delegate(DelegateAction)
  }
  
  enum DelegateAction: Equatable {
    case deleteButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .stepDescriptionEdited(newDescription):
        state.step.description = newDescription
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

struct StepPreview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepPreview(store: .init(
          initialState: .init(
            id: .init(),
            stepNumber: 1,
            step: Recipe.mock.steps.first!.steps.first!
          ),
          reducer: StepPreviewReducer.init
        ))
        .padding()
      }
    }
  }
}
