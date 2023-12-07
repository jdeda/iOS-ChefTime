import SwiftUI
import ComposableArchitecture
import PhotosUI

// TODO: If supporting only a single photo,
// there should be measures here to ensure that we only have a single photo.
struct PhotosReducer: Reducer {
  struct State: Equatable {
    var photos: IdentifiedArrayOf<ImageData>
    let supportSinglePhotoOnly: Bool
    let disableContextMenu: Bool
    var photoEditStatus: PhotoEditStatus? = nil
    var photoEditInFlight: Bool = false
    @BindingState var photoPickerIsPresented: Bool = false
    @BindingState var selection: ImageData.ID?
    @BindingState var photoPickerItem: PhotosPickerItem? = nil
    @PresentationState var alert: AlertState<Action.AlertAction>?
    
    var addButtonIsShowing: Bool {
      if self.photoEditInFlight { false }
      else if self.supportSinglePhotoOnly { self.photos.isEmpty }
      else { true }
    }
    
    init(
      photos: IdentifiedArrayOf<ImageData>,
      supportSinglePhotoOnly: Bool = false,
      disableContextMenu: Bool = false
    ) {
      self.photos = photos
      self.supportSinglePhotoOnly = supportSinglePhotoOnly
      self.disableContextMenu = disableContextMenu
      self.photoEditStatus = nil
      self.photoEditInFlight = false
      self.photoPickerIsPresented = false
      self.selection = photos.first?.id
      self.photoPickerItem = nil
      self.alert = nil
    }
    
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case replaceButtonTapped
    case addButtonTapped
    case deleteButtonTapped
    case applyPhotoEdit(PhotoEditStatus?, ImageData)
    case photoParseError(PhotosError)
    case cancelPhotoEdit
    
    case alert(PresentationAction<AlertAction>)
    
    enum AlertAction: Equatable {
      case dismiss
    }

  }
  
  @Dependency(\.photos) var photosClient
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  
  
  enum PhotoEditStatus: Equatable {
    case replace(ImageData.ID)
    case add(ImageData.ID)
    case addWhenEmpty
  }
  
  
  enum PhotosError: CaseIterable, Error, Equatable {
    case parseError
    case generalError
    case timeoutError
  }
  
  
  enum PhotosCancelID: Hashable, Equatable {
    case photoEdit
  }
  
  // TODO: Handle invalid IDs...
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case .binding(\.$photoPickerItem):
        state.photoPickerIsPresented = false
        guard let item = state.photoPickerItem else {
          state.photoPickerItem = nil
          state.photoEditStatus = nil
          return .none
        }
        state.photoPickerItem = item
        state.photoEditInFlight = true
        return .run { [status = state.photoEditStatus] send in
          guard !Task.isCancelled else { return }
          let imageData = try await withTimeout(for: 10) {
            guard let data = await photosClient.convertPhotoPickerItem(item),
                  let imageData = ImageData(id: .init(rawValue: uuid()), data: data)
            else { throw PhotosError.parseError }
            return imageData
          }
          guard !Task.isCancelled else { return }
          await send(.applyPhotoEdit(status, imageData), animation: .default)
        } catch: { error, send in
          let photosError: PhotosError = {
            if let temp = error as? PhotosError, temp == .parseError  { return .parseError }
            else if let temp = error as? TimedOutError, temp == .timedOut { return .timeoutError }
            else { return .generalError } // This should be impossible to get to.
          }()
          await send(.photoParseError(photosError), animation: .default)
        }
        .cancellable(id: PhotosCancelID.photoEdit, cancelInFlight: true)
        
      case .binding:
        return .none
        
      case .replaceButtonTapped:
        guard let id = state.selection else {
          return .none
        }
        state.photoEditStatus = .replace(id)
        state.photoPickerIsPresented = true
        return .none
        
      case .addButtonTapped:
        if state.photos.isEmpty { state.photoEditStatus = .addWhenEmpty }
        else {
          guard let id = state.selection else { return .none }
          state.photoEditStatus = .add(id)
        }
        state.photoPickerIsPresented = true
        return .none
        
      case .deleteButtonTapped:
        guard let id = state.selection,
              let i = state.photos.index(id: id)
        else {
          return .none
        }
        
        state.photos.remove(id: id)
        state.selection = {
          if state.photos.isEmpty { return nil }
          else if i < state.photos.endIndex { return state.photos[i].id }
          else {
            var i = i
            while i >= state.photos.endIndex { i -= 1 }
            return state.photos[i].id
          }
        }()
        return .none
        
      case let .applyPhotoEdit(status, imageData):
        switch status {
          /// The id represents the id of the image that a photo operation was performed on, such as replace, add, or delete...
          /// it is possible during the time the user was selecting, an image someone could magically mutate the existing selection
          /// and would have implications on how that affects mutation here...
        case let .replace(id):
          guard let i = state.photos.index(id: id) else {
            state.alert = .generalError
            break
          }
          state.photos.replaceSubrange(i...i, with: [imageData])
          state.selection = imageData.id
          break
          
        case let .add(id):
          guard let i = state.photos.index(id: id) else {
            state.alert = .generalError
            break
          }
          state.photos.insert(imageData, at: i + 0)
          state.selection = imageData.id
          break
          
        case .addWhenEmpty:
          state.photos.append(imageData)
          state.selection = imageData.id
          break
          
        case .none:
          break
        }
        state.photoPickerItem = nil
        state.photoEditStatus = nil
        state.photoEditInFlight = false
        return .none
        
      case let .alert(action):
        switch action {
        case .dismiss:
          state.alert = nil
          return .none
          
        case let .presented(action):
          switch action {
          case .dismiss:
            state.alert = nil
            return .none
          }
        }
        
      case let .photoParseError(error):
        state.photoEditInFlight = false
        state.photoEditStatus = nil
        state.photoPickerItem = nil
        state.alert = {
          switch error {
          case .parseError: return .failedToParseImage
          case .generalError: return .generalError
          case .timeoutError: return .timeoutError
          }
        }()
        return .none
        
      case .cancelPhotoEdit:
        state.photoEditInFlight = false
        state.photoEditStatus = nil
        state.photoPickerItem = nil
        return .cancel(id: PhotosCancelID.photoEdit)
      }
    }
  }
}

extension AlertState where Action == PhotosReducer.Action.AlertAction {
  static let failedToParseImage = Self(
    title: {
      TextState("Failed to Parse Image")
    },
    actions: {
      ButtonState {
        TextState("Dismiss")
      }
    },
    message: {
      TextState("The selected image failed to successfully parse, please try again or use another image.")
    }
  )
}

extension AlertState where Action == PhotosReducer.Action.AlertAction {
  static let generalError = Self(
    title: {
      TextState("Oops")
    },
    actions: {
      ButtonState {
        TextState("Dismiss")
      }
    },
    message: {
      TextState("There was a glitch uploading that image, please try again.")
    }
  )
}

extension AlertState where Action == PhotosReducer.Action.AlertAction {
  static let timeoutError = Self(
    title: {
      TextState("Timeout")
    },
    actions: {
      ButtonState {
        TextState("Dismiss")
      }
    },
    message: {
      TextState("The image is taking longer than usual to upload, please try again later.")
    }
  )
}
