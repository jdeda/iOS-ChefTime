import SwiftUI
import ComposableArchitecture
import Tagged
import PhotosUI

/// Moveable Steps
/// moves to new view
///
extension PHAuthorizationStatus {
  var shouldRequestForAuth: Bool {
    switch self {
    case .notDetermined:
      return true
    case .restricted:
      return false
    case .denied:
      return true
    case .authorized:
      return false
    case .limited:
      return false
    @unknown default:
      return true
    }
  }
}

// TODO: Make permissions a dependency
// TODO: Ask for permissions navigation to settings
// TODO: Handle Image Position <-- This would make it legit.
// TODO: Make the steps moveable <-- probably requires a new view

// MARK: - Authorization does not work in previews.
struct StepView: View {
  let store: StoreOf<StepReducer>
  
  struct ViewState: Equatable {
    var step: Recipe.StepSection.Step
    var stepNumber: Int
    var photoPickerItem: PhotosPickerItem?
    @PresentationState var destination: StepReducer.Destination.State?
    var photoAuthStatus: PHAuthorizationStatus
    
    init(_ state: StepReducer.State) {
      self.step = state.step
      self.stepNumber = state.stepNumber
      self.destination = state.destination
      self.photoAuthStatus = state.photoAuthStatus
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      VStack(alignment: .leading) {
        HStack {
          Text("Step \(viewStore.stepNumber)")
            .fontWeight(.medium)
          Spacer()
          // MARK: - Maybe collapse these three options somehow into something simpler
          // is this a static value? or at least i need to observe changes for this value
          if viewStore.photoAuthStatus == .notDetermined {
            Button {
              viewStore.send(.requestAuthPHPhotoLibrary)
            } label: {
              Image(systemName: "camera.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          else if viewStore.photoAuthStatus.shouldRequestForAuth {
            Button {
              viewStore.send(.requestAuthViaSettings)
            } label: {
              Image(systemName: "camera.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          else {
            PhotosPicker(
              selection: viewStore.binding(
                get: \.photoPickerItem,
                send: { .photoPickerItemSelected($0) }
              ),
              matching: .images,
              preferredItemEncoding: .automatic,
              photoLibrary: .shared() // MARK: - Which one to use
            ) {
              Image(systemName: "camera.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            }
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
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10)) // TODO: - Standardize image corner radii in app
        }
        else {
          EmptyView()
        }
      }
      .contextMenu(menuItems: {
        Button {
          viewStore.send(.delegate(.addStepButtonTapped(above: true)), animation: .default)
        } label: {
          Text("Add step above")
        }
        Button {
          viewStore.send(.delegate(.addStepButtonTapped(above: false)), animation: .default)
        } label: {
          Text("Add step below")
        }
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      }, preview: {
        StepContextMenuPreview(state: viewStore.state) // TODO: Get menu preview working
          .frame(minHeight: 200) // TODO: Make dynamic...
          .padding()
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
    var photoAuthStatus: PHAuthorizationStatus = .notDetermined
  }
  
  enum Action: Equatable {
    case stepDescriptionEdited(String)
    case delegate(DelegateAction)
    case photoPickerItemSelected(PhotosPickerItem?)
    case photoPickerItemResult(Data)
    case destination(PresentationAction<Destination.Action>)
    case photoPickerFailure
    case requestAuthPHPhotoLibrary
    case requestAuthViaSettings
    case updateAuthStatus(PHAuthorizationStatus)
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
          title: {
            TextState("Photo Error")
          },
          actions: {
            ButtonState {
              TextState("Dismiss")
            }
          },
          message: {
            TextState("Something went wrong when loading that photo. Please try again or use another photo.")
          }
        ))
        return .none
        
      case let .destination(action):
        return .none
        
      case .requestAuthPHPhotoLibrary:
        return .run { send in
          let a = PHPhotoLibrary.authorizationStatus(for: .readWrite)
          dump(a.rawValue)
          let v = await withUnsafeContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
              continuation.resume(with: .success(status))
            }
          }
          await send(.updateAuthStatus(v))
        }
        
      case .requestAuthViaSettings:
        state.destination = .alert(.init(
          title: {
            TextState("\"ChefTime\" Would Like to Access You Photos")
            // MARK: - Make sure this name matches up to actual app name
          },
          actions: {
            ButtonState {
              TextState("Dismiss")
            }
            ButtonState(action: .confirmNavigateToSettings) {
              TextState("Settings")
            }
          },
          message: {
            TextState("Enable access to upload photos")
            // MARK: - Make sure this name matches up to app privacy photo access string
          }
        ))
        return .none
        
      case let .updateAuthStatus(newStatus):
        state.photoAuthStatus = newStatus
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
    case confirmNavigateToSettings
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
}


// TODO: Improve the StepNumber architecture
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
