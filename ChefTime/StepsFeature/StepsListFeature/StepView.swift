import SwiftUI
import ComposableArchitecture
import Tagged

struct StepView: View {
  let store: StoreOf<StepReducer>
  
  struct ViewState: Equatable {
    var step: Recipe.StepSection.Step
    var stepNumber: Int
    
    init(_ state: StepReducer.State) {
      self.step = state.step
      self.stepNumber = state.stepNumber
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      VStack(alignment: .leading) {
        HStack {
          Text("Step \(viewStore.stepNumber)")
            .fontWeight(.medium)
          Spacer()
          Image(systemName: "camera.fill")
            .font(.caption)
        }
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

struct StepReducer: ReducerProtocol {
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

struct StepView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepView(store: .init(
          initialState: .init(
            id: .init(),
            stepNumber: 1,
            step: Recipe.mock.steps.first!.steps.first!
          ),
          reducer: StepReducer.init
        ))
        .padding()
      }
    }
  }
}
