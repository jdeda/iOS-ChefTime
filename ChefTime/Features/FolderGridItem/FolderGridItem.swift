import ComposableArchitecture
import SwiftUI
import Tagged

// TODO: ContextMenu for the PhotosView should be disabled and relegated to this feature.
// TODO: The PhotosView needs adjusting for adaptable resizing...as wel as the rectangle aspect ratio trick

// MARK: - View
struct FolderGridItemView: View {
  let store: StoreOf<FolderGridItemReducer>
  let isEditing: Bool
  let isSelected: Bool
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        PhotosView(store: store.scope(state: \.photos, action: FolderGridItemReducer.Action.photos))
//          .border(.red)
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
      .clipShape(RoundedRectangle(cornerRadius: 15))
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
                viewStore.send(.photos(.addButtonTapped), animation: .default)
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
          Button {
            viewStore.send(.rename, animation: .default)
          } label: {
            Text("Rename")
          }
          Button {
            viewStore.send(.delegate(.move), animation: .default)
          } label: {
            Text("Move")
          }
          Button(role: .destructive) {
            viewStore.send(.delegate(.delete), animation: .default)
          } label: {
            Text("Delete")
          }
        }
      } preview: {
        FolderGridItemView(store: store, isEditing: isEditing, isSelected: isSelected)
          .disabled(true)
          .frame(minHeight: 200)
      }
      
    }
  }
}

// MARK: - Reducer
struct FolderGridItemReducer: Reducer {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var folder: Folder
    var photos: PhotosReducer.State
    
    init(
      id: ID,
      folder: Folder
    ) {
      self.id = id
      self.folder = folder
      self.photos = .init(
        photos: .init(uniqueElements: (folder.imageData != nil) ? [folder.imageData!] : []),
        supportSinglePhotoOnly: true,
        disableContextMenu: true
      )
    }
  }
  
  enum Action: Equatable {
    case replacePreviewImage
    case rename
    case photos(PhotosReducer.Action)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .replacePreviewImage:
        return .none
        
      case .rename:
        return .none
        
      case .photos, .delegate:
        return .none
      }
    }
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
  }
}

extension FolderGridItemReducer {
  enum DelegateAction: Equatable {
    case move
    case delete
  }
}

// MARK: - Preview
struct FolderGridItemView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FolderGridItemView(
        store: .init(
          initialState: .init(id: .init(), folder: .shortMock),
          reducer: FolderGridItemReducer.init
        ),
        isEditing: false,
        isSelected: false
      )
//      .frame(width: 50, height: 50)
      .padding(50)
    }
  }
}

