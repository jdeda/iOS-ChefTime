import SwiftUI
import ComposableArchitecture
import Tagged

struct StepView: View {
  let store: StoreOf<StepReducer>
  
  struct ViewState: Equatable {
    var step: Recipe.StepSection.Step
    
    init(_ state: StepReducer.State) {
      self.step = state.step
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      VStack(alignment: .center) {
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
          
          Image("burger_bun_01")
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    }
  }
}

struct StepReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var step: Recipe.StepSection.Step
  }
  
  enum Action: Equatable {
    case stepDescriptionEdited(String)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .stepDescriptionEdited(newDescription):
        state.step.description = newDescription
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
            step: Recipe.mock.steps.first!.steps.first!
          ),
          reducer: StepReducer.init
        ))
        .padding()
      }
    }
  }
}
