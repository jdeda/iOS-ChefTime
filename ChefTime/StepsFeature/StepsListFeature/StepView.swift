import SwiftUI
import ComposableArchitecture
import Tagged
import PhotosUI

// TODO: WHAT. Incredible. Make the steps moveable. Incredible.
struct StepView: View {
  let store: StoreOf<StepReducer>
  
  struct ViewState: Equatable {
    var step: Recipe.StepSection.Step
    var stepNumber: Int
    var photoPickerItem: PhotosPickerItem?
    
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
          PhotosPicker.init(selection: viewStore.binding(
            get: \.photoPickerItem,
            send: { .photoPickerItemSelected($0) }
          )) {
            Image(systemName: "camera.fill")
              .font(.caption)
              .foregroundColor(.secondary)
          }
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
        
        if let name = viewStore.step.imageURL?.relativeString {
          Image(name)
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        else {
          EmptyView()
        }
      }
      .contextMenu(menuItems: {
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
        Button(role: .none) {
          viewStore.send(.delegate(.addStepButtonTapped(above: true)), animation: .default)
        } label: {
          Text("Add step above")
        }
        Button(role: .none) {
          viewStore.send(.delegate(.addStepButtonTapped(above: false)), animation: .default)
        } label: {
          Text("Add step below")
        }
      }, preview: {
        StepContextMenuPreview(state: viewStore.state)
//          .frame(minWidth: 400)
          .padding()
//          .padding([.vertical])
      })
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
    case photoPickerItemSelected(PhotosPickerItem?)
  }
  
  enum DelegateAction: Equatable {
    case deleteButtonTapped
    case addStepButtonTapped(above: Bool)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .stepDescriptionEdited(newDescription):
        state.step.description = newDescription
        return .none
        
      case .delegate:
        return .none
        
      case let .photoPickerItemSelected(item):
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

struct StepContextMenuPreview: View {
  let state: StepView.ViewState
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Step \(state.stepNumber)")
          .fontWeight(.medium)
        Spacer()
        Image(systemName: "camera.fill")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      Text(state.step.description)
        .lineLimit(2)
    }
}

  struct StepContextMenuPreview_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        ScrollView {
          StepContextMenuPreview.init(state: .init(.init(
            id: .init(),
            stepNumber: 1,
            step: Recipe.mock.steps.first!.steps.first!
          )))
          .padding()
        }
      }
      
    }
  }
}
