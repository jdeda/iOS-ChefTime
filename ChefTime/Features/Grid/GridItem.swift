import ComposableArchitecture
import SwiftUI
import Tagged


// MARK: - View
struct GridElementView: View {
  let store: StoreOf<GridElementReducer>
  let isEditing: Bool
  let isSelected: Bool
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        ZStack {
          PhotosView(store: store.scope(state: \.gridElement.photos, action: GridElementReducer.Action.photos))
            .opacity(isHidingFolderImages ? 0.0 : 1.0)
          
          PhotosView(store: .init(initialState: .init(photos: .init()), reducer: {}))
            .disabled(true)
            .opacity(!isHidingFolderImages ? 0.0 : 1.0)
        }
        .overlay(alignment: .bottom) {
          if isEditing {
            ZStack(alignment: .bottom) {
              let width: CGFloat = 20
              if isSelected {
                ZStack(alignment: .bottom) {
                  RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.accentColor, lineWidth: 5)
                  
                  Circle()
                    .fill(.primary)
                    .colorInvert()
                    .frame(width: width, height: width)
                    .overlay {
                      Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: width, height: width)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.bottom)
                }
              }
              else {
                Image(systemName: "circle")
                  .frame(width: width, height: width)
                  .foregroundColor(.secondary)
                  .padding(.bottom)
              }
            }
          }
        }
        
        Text(viewStore.gridElement.title)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text(viewStore.gridElement.description)
          .lineLimit(2)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .background(Color.primary.colorInvert())
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .alert(
        store: store.scope(state: \.$destination, action: GridElementReducer.Action.destination),
        state: /GridElementReducer.DestinationReducer.State.alert,
        action: GridElementReducer.DestinationReducer.Action.alert
      )
      .alert("Rename", isPresented: viewStore.binding(
        get: { $0.destination == .renameAlert },
        send: { _ in .destination(.dismiss) }
      )) {
        RenameAlert(name: viewStore.gridElement.title) {
          viewStore.send(.renameAcceptButtonTapped($0), animation: .default)
        }
      }
      .contextMenu { _contextMenu(viewStore) }
    }
  }
}

extension GridElementView {
  @ViewBuilder
  func _contextMenu(_ viewStore: ViewStoreOf<GridElementReducer>) -> some View {
    if viewStore.gridElement.photos.photoEditInFlight &&
        viewStore.gridElement.allowedContextMenuActions.contains(.photos) {
      Button {
        viewStore.send(.photos(.cancelPhotoEdit), animation: .default)
      } label: {
        Text("Cancel Image Upload")
      }
    }
    else {
      if viewStore.gridElement.allowedContextMenuActions.contains(.photos) {
        Menu {
          if viewStore.gridElement.photos.photos.count == 1 {
            Button {
              viewStore.send(.photos(.replaceButtonTapped), animation: .default)
            } label: {
              Text("Replace Image")
            }
            Button(role: .destructive) {
              viewStore.send(.photos(.deleteButtonTapped), animation: .default)
            } label: {
              Text("Delete Image")
            }
          }
          else {
            Button {
              viewStore.send(.photos(.addButtonTapped), animation: .default)
            } label: {
              Text("Add Image")
            }
          }
        } label: {
          Text("Edit Image")
        }
      }
      
      if viewStore.gridElement.allowedContextMenuActions.contains(.rename) {
        Button {
          viewStore.send(.renameButtonTapped, animation: .default)
        } label: {
          Text("Rename")
        }
      }
      
      if viewStore.gridElement.allowedContextMenuActions.contains(.move) {
        Button {
          viewStore.send(.delegate(.move), animation: .default)
        } label: {
          Text("Move")
        }
      }
      
      if viewStore.gridElement.allowedContextMenuActions.contains(.delete) {
        Button(role: .destructive) {
          viewStore.send(.deleteButtonTapped, animation: .default)
        } label: {
          Text("Delete")
        }
      }
    }
  }
}

struct GridElement: Identifiable, Equatable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  var title: String
  var description: String
  var photos: PhotosReducer.State
  var allowedContextMenuActions = Set(AllowedContextMenuActions.allCases)
  
  enum AllowedContextMenuActions: Equatable, Hashable, CaseIterable {
    case share
    case photos
    case rename
    case move
    case delete
  }
}

extension GridElement {
  static let mock = Self.init(
    id: .init(),
    title: Recipe.shortMock.name,
    description: "3/4/12",
    photos: .init(photos: Recipe.shortMock.imageData),
    allowedContextMenuActions: .init(AllowedContextMenuActions.allCases)
  )
}

// MARK: - Reducer
struct GridElementReducer: Reducer {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var gridElement: GridElement
    @PresentationState var destination: DestinationReducer.State?
    
    init(
      id: ID,
      gridElement: GridElement,
      destination: DestinationReducer.State? = nil
    ) {
      self.id = id
      self.gridElement = gridElement
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
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
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
        
      case let .renameAcceptButtonTapped(newTitle):
        state.gridElement.title = newTitle
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
    .ifLet(\.$destination, action: /Action.destination) {
      DestinationReducer()
    }
    Scope(state: \.gridElement.photos, action: /Action.photos) {
      PhotosReducer()
    }
  }
}

extension GridElementReducer {
  struct DestinationReducer: Reducer {
    enum State: Equatable {
      case alert(AlertState<AlertAction>)
      case renameAlert
    }
    
    enum Action: Equatable {
      case alert(AlertAction)
      case renameAlert
    }
    
    var body: some ReducerOf<Self> {
      EmptyReducer()
    }
  }
}

// MARK: - DelegateAction
extension GridElementReducer {
  enum DelegateAction: Equatable {
    case move
    case delete
  }
}

// MARK: - AlertAction
extension GridElementReducer {
  enum AlertAction: Equatable {
    case confirmDeleteButtonTapped
  }
}

// MARK: - AlertState
extension AlertState where Action == GridElementReducer.AlertAction {
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
      TextState("Are you sure you want to delete this folder?")
    }
  )
}

// MARK: - AlertView
private struct RenameAlert: View {
  @State var name: String
  @FocusState private var isTextFieldFocused: Bool
  
  var submitName: (_ name: String) -> Void = unimplemented("RenameAlert.submitName")
  
  var body: some View {
    
    // MARK: - Runtime crash if textfield is wrapped in other views
    TextField("", text: $name)
      .onAppear { self.isTextFieldFocused = true } // MARK: - uncontrolled onAppear
      .focused($isTextFieldFocused)
    // ( •_•) This beautifully understandable block of code allows one to preselect the whole name (⁎❛ᴗ❛⁎ )
      .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
        if let textField = obj.object as? UITextField {
          textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
      }
    
    Button {
    } label: {
      Text("Cancel")
        .fontWeight(.bold) // MARK: - Alert ignores these style modifiers...
    }
    
    Button {
      submitName(name)
    } label: {
      Text("Save")
        .fontWeight(.medium) // MARK: - Alert ignores these style modifiers...
    }
  }
}

// MARK: - Preview
struct GridElementView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      GridElementView(
        store: .init(
          initialState: .init(id: .init(), gridElement: .mock),
          reducer: GridElementReducer.init
        ),
        isEditing: false,
        isSelected: false
      )
      .padding(50)
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}

