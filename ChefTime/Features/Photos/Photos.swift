import SwiftUI
import ComposableArchitecture
import PhotosUI
import Combine

// TODO: Animation slide lag
// TODO: How to play all changes back to original recipe?
// TODO: Maybe change order of adding a photo to next rather than inplace.
// TODO: Fix transition animation from 0 images to 1+ images

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        ZStack {
          VStack {
            Image(systemName: "photo.stack")
              .resizable()
              .scaledToFit()
              .frame(width: 75, height: 75)
              .clipped()
              .foregroundColor(Color(uiColor: .systemGray4))
              .padding()
            Text(viewStore.supportSinglePhotoOnly ? "Add Image" : "Add Images")
              .fontWeight(.bold)
              .foregroundColor(Color(uiColor: .systemGray4))
          }
          .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
          .background(Color(uiColor: .systemGray6))
          .accentColor(.accentColor)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .opacity(viewStore.photos.isEmpty ? 1.0 : 0.0)
          
          ImageSliderView(
            imageDatas: viewStore.photos,
            selection: viewStore.$selection
          )
          .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .opacity(!viewStore.photos.isEmpty ? 1.0 : 0.0 )
        }
        .blur(radius: viewStore.photoEditInFlight ? 5.0 : 0.0)
        .overlay {
          if viewStore.photoEditInFlight {
            ProgressView()
          }
        }
        .disabled(viewStore.photoEditInFlight)
        
        // This allows the ability to disable all the actual logic when
        // a photo edit is in flight but bring the context menu to cancel.
        Color.clear
          .contentShape(Rectangle())
      }
      .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .contextMenu(menuItems: {
        if viewStore.photoEditInFlight {
          Button {
            viewStore.send(.cancelPhotoEdit, animation: .default)
          } label: {
            Text("Cancel")
          }
        }
        if !viewStore.photoEditInFlight && !viewStore.photos.isEmpty {
          Button {
            viewStore.send(.replaceButtonTapped, animation: .default)
          } label: {
            Text("Replace")
          }
          .disabled(viewStore.photoEditInFlight)
        }
        
        
        let addButtonIsShowing: Bool = {
          if viewStore.photoEditInFlight { return false }
          if viewStore.supportSinglePhotoOnly {
            return viewStore.photos.count < 1
          }
          else { return true }
        }()
        if addButtonIsShowing {
          Button {
            viewStore.send(.addButtonTapped, animation: .default)
          } label: {
            Text("Add")
          }
          .disabled(viewStore.photoEditInFlight)
        }
                   
        if !viewStore.photoEditInFlight && !viewStore.photos.isEmpty {
          Button(role: .destructive) {
            viewStore.send(.deleteButtonTapped, animation: .default)
          } label: {
            Text("Delete")
          }
          .disabled(viewStore.photoEditInFlight)
        }
      }, preview: {
        PhotosView(store: store)
        // TODO: The context menu preview version of this view won't update in real-time...
        // So we have to use the original view
      })
      .photosPicker(
        isPresented: viewStore.$photoPickerIsPresented,
        selection: viewStore.$photoPickerItem,
        matching: .images,
        preferredItemEncoding: .compatible,
        photoLibrary: .shared()
      )
      .alert(store: store.scope(state: \.$alert, action: PhotosReducer.Action.alert))
    }
  }
}

// MARK: - Reducer
struct PhotosReducer: Reducer {
  struct State: Equatable {
    var photos: IdentifiedArrayOf<ImageData>
    let supportSinglePhotoOnly: Bool
    var photoEditStatus: PhotoEditStatus? = nil
    var photoEditInFlight: Bool = false
    @BindingState var photoPickerIsPresented: Bool = false
    @BindingState var selection: ImageData.ID?
    @BindingState var photoPickerItem: PhotosPickerItem? = nil
    @PresentationState var alert: AlertState<AlertAction>?
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case replaceButtonTapped
    case addButtonTapped
    case deleteButtonTapped
    case applyPhotoEdit(PhotoEditStatus?, ImageData)
    case alert(PresentationAction<AlertAction>)
    case photoParseError(PhotosError)
    case cancelPhotoEdit
  }
  
  @Dependency(\.photos) var photosClient
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
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
        guard let id = state.selection else { return .none }
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

extension PhotosReducer {
  enum PhotoEditStatus: Equatable {
    case replace(ImageData.ID)
    case add(ImageData.ID)
    case addWhenEmpty
  }
  
  enum AlertAction: Equatable {
    case dismiss
  }
}

extension AlertState where Action == PhotosReducer.AlertAction {
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

extension AlertState where Action == PhotosReducer.AlertAction {
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

extension AlertState where Action == PhotosReducer.AlertAction {
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


struct PhotosContextMenuPreview: View {
  let state: PhotosReducer.State
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
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
        .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
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
            photos: .init(Recipe.longMock.imageData.prefix(0)),
            supportSinglePhotoOnly: false,
            selection: Recipe.longMock.imageData.first?.id
          ),
          reducer: PhotosReducer.init
        ))
      }
      .padding()
    }
  }
}


// MARK: - Async Timeout Algorithm.
extension PhotosReducer {
  /// What if...we could call an operator on a task, called ".timeout", where given for: TimeInterval (say we provide seconds)
  /// and an operation that returns some result, after the provided time, cancel the task and throw a cancellation error...
  /// and...we need to be able to use clocks for this...
  
  ///
  /// Execute an operation in the current task subject to a timeout.
  ///
  /// - Parameters:
  ///   - seconds: The duration in seconds `operation` is allowed to run before timing out.
  ///   - operation: The async operation to perform.
  /// - Returns: Returns the result of `operation` if it completed in time.
  /// - Throws: Throws ``TimedOutError`` if the timeout expires before `operation` completes.
  ///   If `operation` throws an error before the timeout expires, that error is propagated to the caller.
  private func withTimeout<R>(
    for interval: TimeInterval,
    operation: @escaping @Sendable () async throws -> R
  ) async throws -> R {
    return try await withThrowingTaskGroup(of: R.self) { group in
      let deadline = Date(timeIntervalSinceNow: interval)
      
      // Start actual work.
      group.addTask {
        let result = try await operation()
        try Task.checkCancellation()
        return result
      }
      
      // Start timeout child task.
      group.addTask {
        let interval = deadline.timeIntervalSinceNow
        if interval > 0 {
          try await clock.sleep(for: .nanoseconds(UInt64(interval * 1_000_000_000)))
        }
        try Task.checkCancellation()
        
        // We’ve reached the timeout.
        throw TimedOutError.timedOut
      }
      // First finished child task wins, cancel the other task.
      let result = try await group.next()!
      group.cancelAll()
      return result
    }
  }
  
  private enum TimedOutError: Error, Equatable {
    case timedOut
  }
}
