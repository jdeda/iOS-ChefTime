import SwiftUI
import ComposableArchitecture
import Tagged

// MARK: - View
struct StepView: View {
  let store: StoreOf<StepReducer>
  let maxW = UIScreen.main.bounds.width * 0.90
  let index: Int
  @FocusState private var focusedField: StepReducer.FocusField?
  
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(alignment: .leading) {
        Text("Step \(index + 1)") // TODO: Step...
          .font(.caption)
          .fontWeight(.medium)
          .padding(.bottom, 1)
        TextField(
          "...",
          text: viewStore.binding(
            get: \.step.description,
            send: { .stepDescriptionEdited($0) }
          ),
          axis: .vertical
        )
        .focused($focusedField, equals: .description)
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
        
        if let data = viewStore.step.imageData {
          dataToImage(data)!
            .resizable()
            .scaledToFill()
            .frame(width: maxW, height: maxW)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        
        Divider()
      }
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
      .contextMenu {
        Button {
          viewStore.send(.delegate(.insertButtonTapped(.above)), animation: .default)
        } label: {
          Text("Insert Step Above")
        }
        Button {
          viewStore.send(.delegate(.insertButtonTapped(.below)), animation: .default)
        } label: {
          Text("Insert Step Below")
        }
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      } preview: {
        StepContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

// MARK: - Reducer
struct StepReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var step: Recipe.StepSection.Step
    @BindingState var focusedField: FocusField? = nil
    
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
    case stepDescriptionEdited(String)
    case keyboardDoneButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .binding, .delegate:
        return .none
        
      case let .stepDescriptionEdited(newDescription):
        state.step.description = newDescription
        return .none
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
      }
    }
  }
}

extension StepReducer {
  enum FocusField {
    case description
  }
}

extension StepReducer {
  enum DelegateAction: Equatable {
    case insertButtonTapped(AboveBelow)
    case deleteButtonTapped
  }
}

struct StepContextMenuPreview: View {
  let state: StepReducer.State
  let maxW = UIScreen.main.bounds.width * 0.95
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Step \(1)") // TODO: Step...
        .font(.caption)
        .fontWeight(.medium)
        .padding(.bottom, 1)
      Text(state.step.description)
        .lineLimit(2)
    }
  }
}

// MARK: - Preview
struct StepView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepView(store: .init(
          initialState: .init(
            id: .init(),
            step: Recipe.longMock.steps.first!.steps.first!
          ),
          reducer: StepReducer.init
        ), index: 0)
        
        .padding([.horizontal], 10)
        Spacer()
      }
    }
  }
}

