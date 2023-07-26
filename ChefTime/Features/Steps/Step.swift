import SwiftUI
import ComposableArchitecture
import Tagged
import PhotosUI

// MARK: - View
struct StepView: View {
  let store: StoreOf<StepReducer>
  let maxW = UIScreen.main.bounds.width * 0.90 // TODO: This needs to be global or something
  let index: Int // Immutable index representing positon in list.
  @Environment(\.isHidingStepImages) var isHidingStepImages
  @FocusState private var focusedField: StepReducer.FocusField?
  
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        
        HStack {
          Text("Step \(index + 1)") // TODO: Step...
          Spacer()
          
          // TODO: Fix opacity/disable
          Image(systemName: "camera.fill")
            .disabled(!viewStore.photos.photos.isEmpty)
//            .disabled(isHidingStepImages || !viewStore.photos.photos.isEmpty)
//            .opacity(isHidingStepImages ? 0 : 1.0)
        }
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
              .accentColor(.primary)
            }
          }
        }
        
        let isHiding = viewStore.photos.photos.isEmpty || isHidingStepImages
        PhotosView(store: store.scope(
          state: \.photos,
          action: StepReducer.Action.photos
        ))
        .frame(height: isHiding ? 0 : maxW)
        .opacity(isHiding ? 0 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .animation(.default, value: isHidingStepImages)
      }
      .animation(.default, value: isHidingStepImages)
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
    var photos: PhotosReducer.State
    
    init(
      id: ID,
      step: Recipe.StepSection.Step,
      focusedField: FocusField? = nil
    ) {
      self.id = id
      self.step = step
      self.focusedField = focusedField
      self.photos = .init(
        photos: step.imageData,
        selection: step.imageData.first?.id
      )
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
    case photos(PhotosReducer.Action)
    case stepDescriptionEdited(String)
    case keyboardDoneButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding, .delegate, .photos:
        return .none
        
      case let .stepDescriptionEdited(newDescription):
        state.step.description = newDescription
        return .none
        
      case .keyboardDoneButtonTapped:
        state.focusedField = nil
        return .none
      }
    }
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
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

