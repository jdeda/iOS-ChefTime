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
///
///
///
///

// TODO: how 2 align context menu space, should they have a icon too?
// TODO: separaate contwxt mnenus
// TODO: put a limit of 5-10 photos a recpe
// TODO: lots of testing to make sure things go right here...

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  let maxW = UIScreen.main.bounds.width * 0.85
//  @State var selection: Recipe.ImageData.ID?
  
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
          ImageSliderView(
            imageDatas: viewStore.photos,
            selection: viewStore.binding(
              get: \.selection,
              send: { .setSelection($0) }
            )
          )
        }
      }
      .contextMenu(menuItems: {
        // TODO: should they be hidden or grayed out
        if !viewStore.photos.isEmpty {
          Button {
            viewStore.send(.replaceButtonTapped, animation: .default)
          } label: {
            Text("Replace")
          }
        }
        
        Button {
          viewStore.send(.addButtonTapped, animation: .default)
        } label: {
          Text("Add")
        }
        
        if !viewStore.photos.isEmpty {
          Button(role: .destructive) {
            viewStore.send(.deleteButtonTapped, animation: .default)
          } label: {
            Text("Delete")
          }
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
struct PhotosReducer: ReducerProtocol {
  struct State: Equatable {
    var photos: IdentifiedArrayOf<Recipe.ImageData>
    var selection: Recipe.ImageData.ID?
    var photoPickerItem: PhotosPickerItem? = nil
    var photoEditStatus: PhotoEditStatus? = nil
    
    init(recipe: Recipe) {
      self.photos = recipe.imageData
      self.selection = recipe.imageData.first?.id
    }
  }
  
  enum Action: Equatable {
    case setSelection(Recipe.ImageData.ID?)
    case replaceButtonTapped
    case addButtonTapped
    case deleteButtonTapped
    case photoPickerItem(PhotosPickerItem?)
    case dismissPhotosPicker
    case applyPhotoEdit(PhotoEditStatus?, Recipe.ImageData)
  }
  
  @Dependency(\.photos) var photosClient
  @Dependency(\.uuid) var uuid
  
  // TODO: Handle invalid IDs...
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .setSelection(id):
        if let id = id, state.photos.ids.contains(id) {
          state.selection = id
        }
        else {
          state.selection = nil
        }
        return .none
        
      case .replaceButtonTapped:
        // TODO: what if the id is invalid or nil?
        guard let id = state.selection else { return .none }
        state.photoEditStatus = .replace(id)
        return .none
        
      case .addButtonTapped:
        guard let id = state.selection else { return .none }
        state.photoEditStatus = .add(id)
        return .none

      case .deleteButtonTapped:
        guard let id = state.selection,
              let i = state.photos.index(id: id)
        else { return .none }
        state.photos.remove(at: i)
        state.selection = state.photos.elements.first?.id // TODO: WHERE?
        return .none
        
      case let .photoPickerItem(item):
        guard let item else { return .none}
        return .run { [status = state.photoEditStatus] send in
          let data = await photosClient.convertPhotoPickerItem(item)
          // you should be handling errors
          let imageData = Recipe.ImageData(id: .init(rawValue: uuid()), imageData: data)
          await send(.applyPhotoEdit(status, imageData), animation: .default)
        }
      case .dismissPhotosPicker:
        state.photoEditStatus = nil
        return .none
        
      case let .applyPhotoEdit(status, imageData):
        // id represents the id of the image that a photo operation was performed on,
        // such as replace, add, or delete.
        //
        // it is possible during the time the user was selecting
        // an image someone could magically mutate the existing selection
        // and may be worth considering how that affects mutation here.
        switch status {
        case let .replace(id):
          state.photos[id: id]?.imageData = imageData.imageData
          // really, imageData should be immutable, so i should have to put a copy...
          return .none
          
        case let .add(id):
          guard let i = state.photos.index(id: id)
          else { return .none }
          state.photos.insert(imageData, at: i)
          state.selection = imageData.id // TODO: WHERE
          return .none
          
        case .none:
          return .none
        }
      }
    }
  }
}

extension PhotosReducer {
  /// var photoPickerIsPresented: Bool
  /// var photoEditStatus: PhotoEditStatus { case replace, case add  }
  /// var photoIndex: Recipe.ImageData.id
  /// if true -> must have a status and photoIndex
  /// if false -> must NOT have a status nor photoIndex
  
  enum PhotoEditStatus: Equatable {
    case replace(Recipe.ImageData.ID)
    case add(Recipe.ImageData.ID)
  }
}

// PhotosContextMenuPreview
struct PhotosContextMenuPreview: View {
  let state: PhotosReducer.State
  let maxW = UIScreen.main.bounds.width * 0.85
  
  var body: some View {
    VStack {
      if state.photos.isEmpty {
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
          initialState: .init(recipe: .longMock),
          reducer: PhotosReducer.init
        ))
      }
      .padding()
    }
  }
}

