import ComposableArchitecture

struct StepReducer: Reducer {
  struct State: Equatable, Identifiable {
    var id: Recipe.StepSection.Step.ID {
      self.step.id
    }
    
    @BindingState var step: Recipe.StepSection.Step
    @BindingState var focusedField: FocusField? = nil
    var photos: PhotosReducer.State {
      didSet {
        self.step.imageData = self.photos.photos
      }
    }
    
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
