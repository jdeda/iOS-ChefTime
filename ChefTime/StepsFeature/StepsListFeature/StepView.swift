import SwiftUI
import ComposableArchitecture
import Tagged
import PhotosUI

/// Moveable Steps
///
///

// TODO: O - Make the steps moveable <-- probably requires a new view
// TODO: O - Ask for permissions
// TODO: X - Fit Images
// TODO: O - Handle Image Types (Logic + Alert)
// TODO: O - Handle Image Position <-- This would make it legit.
struct StepView: View {
  let store: StoreOf<StepReducer>
  
  struct ViewState: Equatable {
    var step: Recipe.StepSection.Step
    var stepNumber: Int
    var photoPickerItem: PhotosPickerItem?
    @PresentationState var destination: StepReducer.Destination.State?
    
    init(_ state: StepReducer.State) {
      self.step = state.step
      self.stepNumber = state.stepNumber
      self.destination = state.destination
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      VStack(alignment: .leading) {
        HStack {
          Text("Step \(viewStore.stepNumber)")
            .fontWeight(.medium)
          Spacer()
          PhotosPicker(
            selection: viewStore.binding(
              get: \.photoPickerItem,
              send: { .photoPickerItemSelected($0) }
            ),
            matching: .images,
            preferredItemEncoding: .automatic,
            photoLibrary: .shared()
          ) {
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
        
        if let imageData = viewStore.step.imageData, let image = dataToImage(imageData) {
          image
            .resizable()
            .scaledToFill()
            .frame(width: .infinity, height: 200)
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
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
        state: /StepReducer.Destination.State.alert,
        action: StepReducer.Destination.Action.alert
      )
    }
  }
}

struct StepReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var stepNumber: Int
    var step: Recipe.StepSection.Step
    @PresentationState var destination: Destination.State?
  }
  
  enum Action: Equatable {
    case stepDescriptionEdited(String)
    case delegate(DelegateAction)
    case photoPickerItemSelected(PhotosPickerItem?)
    case photoPickerItemResult(Data)
    case destination(PresentationAction<Destination.Action>)
    case photoPickerFailure
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
        
        // TODO: Care for image support types...
        // TODO: Care for permissions...
      case let .photoPickerItemSelected(item):
        guard let item else { return .none }
        return .run { send in
          guard let data = try? await item.loadTransferable(type: Data.self)
          else {
            await send(.photoPickerFailure)
            return
          }
          await send(.photoPickerItemResult(data))
        }
      case let .photoPickerItemResult(data):
        state.step.imageData = data
        return .none
        
      case .photoPickerFailure:
        state.destination = .alert(.init(
          title: { TextState("Photo Error")},
          actions: {
            .init { TextState("Dismiss") }
          },
          message: {
            TextState("Something went wrong when loading that photo. Please try again or use another photo.")
          }
        ))
        return .none
        
      case let .destination(action):
        return .none
      }
    }
  }
}

// MARK: - Destination. May seem unncessary, but may leave as much
// in the event we add a permissions, which we may want to execute more logic.
// If it turns out that even then we don't need to handle any extra logic
// with that ourselves, than this can be deleted.
// TODO: May want a more descriptive message on the image load failure.
extension StepReducer {
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
    case accept
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
