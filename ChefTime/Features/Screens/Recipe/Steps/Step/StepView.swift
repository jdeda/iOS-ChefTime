import SwiftUI
import ComposableArchitecture

struct StepView: View {
  let store: StoreOf<StepReducer>
  let index: Int // Immutable index representing positon in list.
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingImages) var isHidingImages
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
            .disabled(isHidingImages || !viewStore.photos.photos.isEmpty || viewStore.photos.photoEditInFlight)
            .opacity(isHidingImages ? 0.0 : 1.0)
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
          if isHidingImages { return true }
          else if !viewStore.photos.photos.isEmpty { return false }
          else {
            return !(viewStore.photos.photoEditStatus == .addWhenEmpty && viewStore.photos.photoEditInFlight)
          }
        }()
        PhotosView(store: store.scope(state: \.photos, action: StepReducer.Action.photos))
        .frame(height: isHidingPhotosView ? 0 : maxScreenWidth.maxWidth)
        .opacity(isHidingPhotosView ? 0 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .disabled(isHidingPhotosView)
        
        Spacer()
      }
      .animation(.default, value: isHidingImages) // TODO: Why?
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

#Preview {
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

