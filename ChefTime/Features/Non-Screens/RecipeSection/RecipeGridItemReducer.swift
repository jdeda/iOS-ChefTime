import ComposableArchitecture

@Reducer
struct RecipeGridItemReducer {
  struct State: Equatable, Identifiable {
    var id: Recipe.ID { recipe.id }
    var recipe: Recipe
    var photos: PhotosReducer.State {
      didSet { self.recipe.imageData = self.photos.photos }
    }
    @PresentationState var destination: DestinationReducer.State?
    
    init(
      recipe: Recipe,
      destination: DestinationReducer.State? = nil
    ) {
      self.recipe = recipe
      self.photos = .init(
        photos: .init(uniqueElements: (recipe.imageData.first != nil) ? [recipe.imageData.first!] : []),
        supportSinglePhotoOnly: true,
        disableContextMenu: true
      )
      self.destination = destination
    }
  }
  
  enum Action: Equatable, BindableAction {
    case deleteButtonTapped
    case replacePreviewImage
    case renameButtonTapped
    case renameAcceptButtonTapped(String)
    case binding(BindingAction<State>)
    case destination(PresentationAction<DestinationReducer.Action>)
    case photos(PhotosReducer.Action)
    
    case delegate(DelegateAction)
    @CasePathable
    enum DelegateAction: Equatable {
      case move
      case delete
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    CombineReducers {
      Scope(state: \.photos, action: \.photos, child: PhotosReducer.init)
      Reduce { state, action in
        switch action {
          
        case .deleteButtonTapped:
          state.destination = .alert(.delete)
          return .none
          
        case .replacePreviewImage:
          return .none
          
        case .renameButtonTapped:
          state.destination = .renameAlert
          return .none
          
        case let .renameAcceptButtonTapped(newName):
          state.recipe.name = newName
          state.destination = nil
          return .none
          
        case .destination(.presented(.alert(.confirmDeleteButtonTapped))):
          state.destination = nil
          return .run { send in
            // This dismiss fixes bug where alert will reappear and dismiss immediately upon sending .delegate(.delegate)
            // However, this bug seems to happen because you are returning an action in the .presented.
            // Niling the destination state then returning the delegate, all synchronously does not solve the problem!
            await dismiss()
            await send(.delegate(.delete))
          }
          
        case .binding, .photos, .delegate, .destination:
          return .none
        }
      }
      .ifLet(\.$destination, action: \.destination, destination: DestinationReducer.init)
    }
  }
  
  @Reducer
  struct DestinationReducer {
    enum State: Equatable {
      case alert(AlertState<Action.AlertAction>)
      case renameAlert
    }
    
    enum Action: Equatable {
      case renameAlert
      
      case alert(AlertAction)
      @CasePathable
      enum AlertAction: Equatable {
        case confirmDeleteButtonTapped
      }
    }
    
    var body: some ReducerOf<Self> {
      EmptyReducer()
    }
  }
}

extension AlertState where Action == RecipeGridItemReducer.DestinationReducer.Action.AlertAction {
  static let delete = Self(
    title: {
      TextState("Delete")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteButtonTapped) {
        TextState("Yes")
      }
      ButtonState(role: .cancel) {
        TextState("No")
      }
    },
    message: {
      TextState("Are you sure you want to delete this recipe?")
    }
  )
}
