import ComposableArchitecture
import SwiftUI
import Tagged


// MARK: - View
struct RecipeGridItemView: View {
  let store: StoreOf<RecipeGridItemReducer>
  let isEditing: Bool
  let isSelected: Bool
  @Environment(\.isHidingImages) var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        ZStack {
          PhotosView(store: store.scope(state: \.photos, action: RecipeGridItemReducer.Action.photos))
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
        
        Text(viewStore.recipe.name)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text("Created 8/13/23")
          .lineLimit(2)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .background(Color.primary.colorInvert())
      .clipShape(RoundedRectangle(cornerRadius: 15))
      
      .alert(
        store: store.scope(state: \.$destination, action: RecipeGridItemReducer.Action.destination),
        state: /RecipeGridItemReducer.DestinationReducer.State.alert,
        action: RecipeGridItemReducer.DestinationReducer.Action.alert
      )
      .alert("Rename", isPresented: viewStore.binding(
        get: { $0.destination == .renameAlert },
        send: { _ in .destination(.dismiss) }
      )) {
        RenameAlert(name: viewStore.recipe.name) {
          viewStore.send(.renameAcceptButtonTapped($0), animation: .default)
        }
      }
      .contextMenu {
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

// MARK: - Reducer
struct RecipeGridItemReducer: Reducer {
  struct State: Equatable, Identifiable {
    var id: Recipe.ID {
      recipe.id
    }
    
    var recipe: Recipe
    var photos: PhotosReducer.State
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
    case updateRecipePhotos
    case binding(BindingAction<State>)
    case destination(PresentationAction<DestinationReducer.Action>)
    case photos(PhotosReducer.Action)
    case delegate(DelegateAction)
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    CombineReducers {
      Scope(state: \.photos, action: /Action.photos) {
        PhotosReducer()
      }
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
          
        case .updateRecipePhotos:
          state.recipe.imageData = state.photos.photos
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
    }
    .onChange(of: \.photos.photos) { _, _ in
      Reduce { _, _ in
          .send(.updateRecipePhotos)
      }
    }
  }
}

extension RecipeGridItemReducer {
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
extension RecipeGridItemReducer {
  enum DelegateAction: Equatable {
    case move
    case delete
  }
}

// MARK: - AlertAction
extension RecipeGridItemReducer {
  enum AlertAction: Equatable {
    case confirmDeleteButtonTapped
  }
}

// MARK: - AlertState
extension AlertState where Action == RecipeGridItemReducer.AlertAction {
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
struct RecipeGridItemView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      RecipeGridItemView(
        store: .init(
          initialState: .init(recipe: .shortMock),
          reducer: RecipeGridItemReducer.init
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

