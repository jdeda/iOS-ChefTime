import SwiftUI
import ComposableArchitecture
import PhotosUI
///   0. ideal, but may be impoosible w/o going to great lengths -
///   double click, get a multi-select, validate and notify in real time when tapped if image didnt work
///   1, double click, get a multi-select, if some images fail, notify them that some images didn't work
///   2. single click, get a single select for the specific image indexed, ntofiy them that an image didnt work
///   3. double click, nav to new page, showing selected images, user can tap an image to get a sheet and notify if didntt work
///
/// must worry about add, remove, replace, order (but not reorder)
/// - tap gestures won't work here
/// - hold -> context menu -> 3 buttons ->  replace, add, remove
/// - click -> navigation -> grid view -> tap to replace

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  let maxW = UIScreen.main.bounds.width * 0.85
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        if viewStore.photos.isEmpty {
          VStack { // TODO: Mess with color scheme here.
            Image(systemName: "photo.stack")
              .resizable()
              .scaledToFit()
              .frame(width: 75, height: 75)
              .clipped()
              .foregroundColor(Color(uiColor: .systemGray4))
              .padding()
            Text("Add Images")
              .fontWeight(.bold) // TODO: To be or not to be bold...
              .foregroundColor(Color(uiColor: .systemGray4))
          }
          .frame(width: maxW, height: maxW)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .accentColor(.accentColor)
        }
        else  {
          ImageSliderView(imageDatas: viewStore.photos)
        }
      }
      .onTapGesture(count: 2, perform: {
        viewStore.send(.setPhotoPickerIsPresented(true))
      })
      .photosPicker(
        isPresented: viewStore.binding(
          get: \.photoPickerIsPresented,
          send: { .setPhotoPickerIsPresented($0) }
        ),
        selection: viewStore.binding(
          get: \.photoPickerItems,
          send: { .photoPickerItems($0) }
        ),
        maxSelectionCount: viewStore.maxPhotoPickerItemCount,
        selectionBehavior: .ordered,
        matching: .images,
        preferredItemEncoding: .compatible,
        photoLibrary: .shared()
      )
    }
  }
}

// MARK: - Reducer
struct PhotosReducer: ReducerProtocol {
  struct State: Equatable {
    var photos: IdentifiedArrayOf<Recipe.ImageData>
    var photoPickerItems: [PhotosPickerItem] = []
    var maxPhotoPickerItemCount: Int = 3
    var photoPickerIsPresented: Bool = false
    
    init(recipe: Recipe) {
      self.photos = recipe.imageData
    }
  }
  
  enum Action: Equatable {
    case photosTapped
    case photoPickerItems([PhotosPickerItem])
    case setPhotoPickerIsPresented(Bool)
    case setPhotos(IdentifiedArrayOf<Recipe.ImageData>)
  }
  
  @Dependency(\.photos) var photosClient
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .photosTapped:
        return .none
        
      case let .photoPickerItems(newPhotoPickerItems):
        return .run { send in
          let data = await photosClient.convertPhotoPickerItems(newPhotoPickerItems)
          await send(.setPhotos(.init(uniqueElements: data.map {
            .init(id: .init(rawValue: uuid()), imageData: $0)
          })))
        }
        
      case let .setPhotoPickerIsPresented(isPresented):
        state.photoPickerIsPresented = isPresented
        return .none
        
      case let .setPhotos(newPhotos):
        state.photos = newPhotos
        return .none
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
          initialState: .init(recipe: .longMock),
          reducer: PhotosReducer.init
        ))
      }
      .padding()
    }
  }
}

