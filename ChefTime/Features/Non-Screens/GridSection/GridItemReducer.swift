import Foundation
import ComposableArchitecture
import Tagged

struct GridItemReducer<ID: Equatable & Hashable>: Reducer {
  struct State: Equatable, Identifiable {
    let id: ID
    var name: String
    var description: String
    var photos: PhotosReducer.State
    let enabledContextMenuActions: Set<ContextMenuActions>
    @PresentationState var destination: DestinationReducer.State?
    var isSelected: Bool
    
    init(
      id: ID,
      name: String,
      description: String,
      imageData: ImageData? = nil,
      enabledContextMenuActions: Set<ContextMenuActions> = .init(ContextMenuActions.allCases),
      destination: DestinationReducer.State? = nil
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.photos = .init(
        photos: imageData.flatMap({[$0]}) ?? [],
        supportSinglePhotoOnly: true,
        disableContextMenu: true
      )
      self.destination = destination
      self.enabledContextMenuActions = enabledContextMenuActions
      self.isSelected = false
    }
  }
  
  enum Action: Equatable, BindableAction {
    case gridItemSelected
    case deleteButtonTapped
    case replacePreviewImage
    case renameButtonTapped
    case renameAcceptButtonTapped(String)
    case binding(BindingAction<State>)
    case destination(PresentationAction<DestinationReducer.Action>)
    case photos(PhotosReducer.Action)
    
    case delegate(DelegateAction)
    
    enum DelegateAction: Equatable {
      case gridItemTapped
      case gridItemSelected
      case delete
    }
  }
  
  
  enum ContextMenuActions: CaseIterable, Hashable {
    case rename
    case delete
    case editPhotos
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Scope(state: \.photos, action: /GridItemReducer.Action.photos) {
      PhotosReducer()
    }
    Reduce { state, action in
      switch action {
        
      case .gridItemSelected:
        state.isSelected.toggle()
        return .send(.delegate(.gridItemSelected), animation: .default)
        
      case .deleteButtonTapped:
        state.destination = .alert(.init(
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
            TextState("Are you sure you want to delete this?")
          }
        ))
        return .none
        
      case .replacePreviewImage:
        return .none
        
      case .renameButtonTapped:
        state.destination = .renameAlert
        return .none
        
      case let .renameAcceptButtonTapped(newName):
        state.name = newName
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
    .ifLet(\.$destination, action: /GridItemReducer.Action.destination) {
      DestinationReducer()
    }
  }
  
  struct DestinationReducer: Reducer {
    enum State: Equatable {
      case alert(AlertState<Action.AlertAction>)
      case renameAlert
    }
    
    enum Action: Equatable {
      case renameAlert
      
      case alert(AlertAction)
      
      enum AlertAction: Equatable {
        case confirmDeleteButtonTapped
      }
    }
    
    var body: some ReducerOf<Self> {
      EmptyReducer()
    }
  }
}

// TODO: How to make this static instance?
//extension AlertState where Action == GridItemReducer<ID>.DestinationReducer.Action.AlertAction {
//  static let delete = Self(
//    title: {
//      TextState("Delete")
//    },
//    actions: {
//      ButtonState(role: .destructive, action: .confirmDeleteButtonTapped) {
//        TextState("Yes")
//      }
//      ButtonState(role: .cancel) {
//        TextState("No")
//      }
//    },
//    message: {
//      TextState("Are you sure you want to delete this?")
//    }
//  )
//}
