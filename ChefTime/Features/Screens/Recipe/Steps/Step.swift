import SwiftUI
import ComposableArchitecture
import Tagged
import PhotosUI

// MARK: - View
struct StepView: View {
  let store: StoreOf<StepReducer>
  let index: Int // Immutable index representing positon in list.
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingStepImages) var isHidingStepImages
  @FocusState private var focusedField: StepReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        VStack {
          HStack {
            Text("Step \(index + 1)")
            Spacer()
            Button {
              viewStore.send(.photoPickerButtonTapped)
            } label: {
              Image(systemName: "camera.fill")
                .accentColor(.primary)
            }
            .disabled(isHidingStepImages || !viewStore.photos.photos.isEmpty || viewStore.photos.photoEditInFlight)
            .opacity(isHidingStepImages ? 0.0 : 1.0)
          }
          .fontWeight(.medium)
          .padding(.bottom, 1)
          
          TextField("...", text: viewStore.$step.description, axis: .vertical)
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
                  .accentColor(.primary)
                }
              }
            }
        }
        
        // TODO: This value doesn't work right :(
        // Display the photos only if we are not hiding the photos
        // and if we have photos or we are uploading the first photo.
        let isHidingPhotosView: Bool = {
          if isHidingStepImages { return true }
          else if !viewStore.photos.photos.isEmpty { return false }
          else {
            return !(viewStore.photos.photoEditStatus == .addWhenEmpty && viewStore.photos.photoEditInFlight)
          }
        }()
        PhotosView(store: store.scope(
          state: \.photos,
          action: StepReducer.Action.photos
        ))
        .frame(height: isHidingPhotosView ? 0 : maxScreenWidth.maxWidth)
        .opacity(isHidingPhotosView ? 0 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .disabled(isHidingPhotosView)
      }
      .animation(.default, value: isHidingStepImages) // TODO: Why?
      .synchronize(viewStore.$focusedField, $focusedField)
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
        StepContextMenuPreview(state: viewStore.state, index: index)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

// MARK: - Reducer
struct StepReducer: Reducer {
  struct State: Equatable, Identifiable {
    var id: Recipe.StepSection.Step.ID {
      self.step.id
    }
    
    @BindingState var step: Recipe.StepSection.Step
    @BindingState var focusedField: FocusField? = nil
    var photos: PhotosReducer.State
    
    init(
      step: Recipe.StepSection.Step,
      focusedField: FocusField? = nil
    ) {
      self.step = step
      self.focusedField = focusedField
      self.photos = .init(photos: step.imageData)
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
    case photos(PhotosReducer.Action)
    case keyboardDoneButtonTapped
    case photoPickerButtonTapped
    case photoImagesDidChange
  }
  
  @Dependency(\.photos) var photosClient
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    CombineReducers {
      BindingReducer()
      Reduce { state, action in
        switch action {
        case .binding, .delegate, .photos:
          return .none
          
        case .keyboardDoneButtonTapped:
          state.focusedField = nil
          return .none
          
        case .photoPickerButtonTapped:
          state.photos.photoEditStatus = .addWhenEmpty
          state.photos.photoPickerIsPresented = true
          return .none
          
        case .photoImagesDidChange:
          state.step.imageData = state.photos.photos
          return .none
        }
      }
      Scope(state: \.photos, action: /Action.photos) {
        PhotosReducer()
      }
    }
    .onChange(of: \.photos.photos, { _, _ in
      Reduce { _, _ in
          .send(.photoImagesDidChange)
      }
    })
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
  let index: Int // Immutable index representing positon in list.
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Step \(index + 1)")
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
            step: Recipe.longMock.stepSections.first!.steps.first!
          ),
          reducer: StepReducer.init
        ), index: 0)
        
        .padding([.horizontal])
        Spacer()
      }
    }
  }
}

