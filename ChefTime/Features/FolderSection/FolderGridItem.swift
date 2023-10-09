import ComposableArchitecture
import SwiftUI
import Tagged


// MARK: - View
struct FolderGridItemView: View {
  let store: StoreOf<FolderGridItemReducer>
  let isEditing: Bool
  let isSelected: Bool
  @Environment(\.isHidingImages) var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        ZStack {
          PhotosView(store: store.scope(state: \.photos, action: FolderGridItemReducer.Action.photos))
            .opacity(isHidingImages ? 0.0 : 1.0)
          
          PhotosView(store: .init(initialState: .init(photos: .init()), reducer: {}))
            .disabled(true)
            .opacity(!isHidingImages ? 0.0 : 1.0)
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
        
        Text(viewStore.folder.name)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text("\(viewStore.folder.recipes.count) recipes")
          .lineLimit(2)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .background(Color.primary.colorInvert())
      .clipShape(RoundedRectangle(cornerRadius: 15))
      
      .alert(
        store: store.scope(state: \.$destination, action: FolderGridItemReducer.Action.destination),
        state: /FolderGridItemReducer.DestinationReducer.State.alert,
        action: FolderGridItemReducer.DestinationReducer.Action.alert
      )
      .alert("Rename", isPresented: viewStore.binding(
        get: { $0.destination == .renameAlert },
        send: { _ in .destination(.dismiss) }
      )) {
        RenameAlert(name: viewStore.folder.name) {
          viewStore.send(.renameAcceptButtonTapped($0), animation: .default)
        }
      }
      .contextMenu {
        if viewStore.photos.photoEditInFlight {
          Button {
            viewStore.send(.photos(.cancelPhotoEdit), animation: .default)
          } label: {
            Text("Cancel Image Upload")
          }
        }
        else {
          Menu {
            if viewStore.photos.photos.count == 1 {
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
          if !viewStore.folder.folderType.isSystem {
            Button {
              viewStore.send(.renameButtonTapped, animation: .default)
            } label: {
              Text("Rename")
            }
            Button {
              viewStore.send(.delegate(.move), animation: .default)
            } label: {
              Text("Move")
            }
            Button(role: .destructive) {
              viewStore.send(.deleteButtonTapped, animation: .default)
            } label: {
              Text("Delete")
            }
          }
        }
      }
    }
  }
}

// MARK: - Reducer
struct FolderGridItemReducer: Reducer {
  struct State: Equatable, Identifiable {
    var id: Folder.ID {
      folder.id
    }
    
    var folder: Folder
    var photos: PhotosReducer.State
    @PresentationState var destination: DestinationReducer.State?
    
    init(
      folder: Folder,
      destination: DestinationReducer.State? = nil
    ) {
      self.folder = folder
      self.photos = .init(
        photos: .init(uniqueElements: (folder.imageData != nil) ? [folder.imageData!] : []),
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
        
      case let .renameAcceptButtonTapped(newName):
        state.folder.name = newName
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
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
  }
}

extension FolderGridItemReducer {
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
extension FolderGridItemReducer {
  enum DelegateAction: Equatable {
    case move
    case delete
  }
}

// MARK: - AlertAction
extension FolderGridItemReducer {
  enum AlertAction: Equatable {
    case confirmDeleteButtonTapped
  }
}

// MARK: - AlertState
extension AlertState where Action == FolderGridItemReducer.AlertAction {
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
struct FolderGridItemView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FolderGridItemView(
        store: .init(
          initialState: .init(folder: .shortMock),
          reducer: FolderGridItemReducer.init
        ),
        isEditing: false,
        isSelected: false
      )
      //      .frame(width: 50, height: 50)
      .padding(50)
      .onAppear {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
      }
    }
  }
}

