import SwiftUI
import ComposableArchitecture
import PhotosUI

// TODO: how 2 align context menu space, should they have a icon too?
// TODO: put a limit of 5-10 photos a recpe
// TODO: ask for user permissions
// TODO: fix sizing issues

// TODO: Move maxW UIScreen.main.bounds
// TODO: Animation slide lag
// TODO: Add progress view, that blocks any incoming edits and ui interactions, and cancellable,
// and it alerts when failed
// TODO: How to play all changes back to original recipe?
// TODO: Maybe change order of adding a photo to next rather than inplace.
// TODO: Fix transition animation from 0 images to 1+ images

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  let maxW = UIScreen.main.bounds.width * 0.90
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        if viewStore.photos.isEmpty {
          VStack {
            Image(systemName: "photo.stack")
              .resizable()
              .scaledToFit()
              .frame(width: 75, height: 75)
              .clipped()
              .foregroundColor(Color(uiColor: .systemGray4))
              .padding()
            Text("Add Images")
              .fontWeight(.bold)
              .foregroundColor(Color(uiColor: .systemGray4))
          }
          .frame(width: maxW, height: maxW)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .accentColor(.accentColor)
        }
        else  {
          ImageSliderView(
            imageDatas: viewStore.photos,
            selection: viewStore.binding(
              get: \.selection,
              send: { .photoSelectionChanged($0) }
            )
          )
        }
      }
      .blur(radius: viewStore.photoEditInFlight ? 5.0 : 0.0)
      .overlay {
        if viewStore.photoEditInFlight {
          ProgressView()
            .frame(width: maxW, height: maxW)
          
        }
      }
      .contextMenu(menuItems: {
        if !viewStore.photos.isEmpty {
          Button {
            viewStore.send(.replaceButtonTapped, animation: .default)
          } label: {
            Text("Replace")
          }
          .disabled(viewStore.photoEditInFlight)
        }
        
        Button {
          viewStore.send(.addButtonTapped, animation: .default)
        } label: {
          Text("Add")
        }
        .disabled(viewStore.photoEditInFlight)
        
        if !viewStore.photos.isEmpty {
          Button(role: .destructive) {
            viewStore.send(.deleteButtonTapped, animation: .default)
          } label: {
            Text("Delete")
          }
          .disabled(viewStore.photoEditInFlight)
        }
      }, preview: {
        PhotosContextMenuPreview(state: viewStore.state)
      })
      .photosPicker(
        isPresented: viewStore.binding(
          get: { $0.photoEditStatus != nil },
          send: { _ in .dismissPhotosPicker }
        ),
        selection: viewStore.binding(
          get: \.photoPickerItem,
          send: { .photoPickerItem($0) }
        ),
        matching: .images,
        preferredItemEncoding: .compatible,
        photoLibrary: .shared()
      )
    }
  }
}

// MARK: - Reducer
struct PhotosReducer: Reducer {
  struct State: Equatable {
    var photos: IdentifiedArrayOf<ImageData>
    var selection: ImageData.ID?
    var photoPickerItem: PhotosPickerItem? = nil
    var photoEditStatus: PhotoEditStatus? = nil
    
    var photoEditInFlight: Bool {
      photoEditStatus != nil
    }
  }
  
  enum Action: Equatable {
    case photoSelectionChanged(ImageData.ID?)
    case replaceButtonTapped
    case addButtonTapped
    case deleteButtonTapped
    case photoPickerItem(PhotosPickerItem?)
    case dismissPhotosPicker
    case applyPhotoEdit(PhotoEditStatus?, ImageData)
  }
  
  @Dependency(\.photos) var photosClient
  @Dependency(\.uuid) var uuid
  
  // TODO: Handle invalid IDs...
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .photoSelectionChanged(id):
        if let id = id, state.photos.ids.contains(id) {
          state.selection = id
        }
        else {
          state.selection = nil
        }
        return .none
        
        // TODO: Checking if in flight here not super necessary.
      case .replaceButtonTapped:
        guard let id = state.selection
        else { return .none } // TODO: what if the id is invalid or nil?
        
        state.photoEditStatus = .replace(id)
        return .none
        
      case .addButtonTapped:
        if state.photos.isEmpty {
          state.photoEditStatus = .addWhenEmpty
          return .none
        }
        else {
          guard let id = state.selection else { return .none }
          state.photoEditStatus = .add(id)
          return .none
        }
        
      case .deleteButtonTapped:
        guard let id = state.selection,
              let i = state.photos.index(id: id)
        else { return .none }
        
        state.photos.remove(id: id)
        state.selection = nil
        if state.photos.isEmpty {
          state.selection = nil
          return .none
        }
        else if i <= state.photos.count - 1 {
          state.selection = state.photos[i].id
        }
        else {
          var i = i
          while i > state.photos.count -  1 {
            i -= 1
          }
          state.selection = state.photos[i].id
        }
        return .none
      
      case let .photoPickerItem(item):
        guard let item else { return .none}
        return .run { [status = state.photoEditStatus] send in
          try await Task.sleep(for: .seconds(1))
          guard let data = await photosClient.convertPhotoPickerItem(item),
                let imageData = ImageData(id: .init(rawValue: uuid()), data: data)
          else {
            return
          }
          // you should be handling errors
          await send(.applyPhotoEdit(status, imageData), animation: .default)
        }
      case .dismissPhotosPicker:
        state.photoEditStatus = nil
        return .none
        
      case let .applyPhotoEdit(status, imageData):
        /// The id represents the id of the image that a photo operation was performed on, such as replace, add, or delete...
        /// it is possible during the time the user was selecting, an image someone could magically mutate the existing selection
        /// and would have implications on how that affects mutation here...
        switch status {
        case let .replace(id):
          guard let i = state.photos.index(id: id)
          else { return .none } // TODO: ERROR HANDLE
          state.photos.replaceSubrange(i...i, with: [imageData])
          state.photoEditStatus = nil
          return .none
          
        case let .add(id):
          guard let i = state.photos.index(id: id) else { return .none }
          state.photos.insert(imageData, at: i + 0)
          // TODO: To insert in place, or after?
          state.selection = imageData.id
          state.photoEditStatus = nil
          return .none
    
        case .addWhenEmpty:
          state.photos.append(imageData) // Possible could insert not a zero?
          state.selection = imageData.id
          state.photoEditStatus = nil
          return .none
          
        case .none:
          return .none
        }
      }
    }
  }
}

extension PhotosReducer {
  enum PhotoEditStatus: Equatable {
    case replace(ImageData.ID)
    case add(ImageData.ID)
    case addWhenEmpty
  }
}

struct PhotosContextMenuPreview: View {
  let state: PhotosReducer.State
  let maxW = UIScreen.main.bounds.width * 0.85
  
  var body: some View {
    VStack {
      if state.photos.isEmpty {
        VStack {
          Image(systemName: "photo.stack")
            .resizable()
            .scaledToFit()
            .frame(width: 75, height: 75)
            .clipped()
            .foregroundColor(Color(uiColor: .systemGray4))
            .padding()
          Text("Add Images")
            .fontWeight(.bold)
            .foregroundColor(Color(uiColor: .systemGray4))
        }
        .frame(width: maxW, height: maxW)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .accentColor(.accentColor)
      }
      else  {
        ImageSliderView(
          imageDatas: state.photos,
          selection: .constant(state.selection)
        )
      }
    }
  }
}

// MARK: - Preview
struct PhotosView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        PhotosView(store: .init(
          initialState: .init(
            photos: .init(Recipe.longMock.imageData.prefix(1)),
            selection: Recipe.longMock.imageData.first?.id
          ),
          reducer: PhotosReducer.init
        ))
      }
      .padding()
    }
  }
}

