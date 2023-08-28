import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FoldersView: View {
  let store: StoreOf<FoldersReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  var width: CGFloat { maxScreenWidth.maxWidth * 0.40 }
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      //      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 10) {
          ForEach(viewStore.folders) { folder in
            FolderItemView(folder: folder, isEditing: viewStore.isEditing, width: width, isSelected: viewStore.selection.contains(folder.id))
              .frame(maxWidth: width)
              .tag(folder.id)
              .onTapGesture {
                if viewStore.isEditing {
                  viewStore.send(.folderSelectionTapped(folder.id), animation: .default)
                }
                else {
                  viewStore.send(.folderTapped(folder.id), animation: .default)
                }
              }
          }
        }
        .listSectionSeparator(.hidden)
        .listRowSeparator(.hidden)
        .padding(.horizontal)
      }
      .listStyle(.plain)
      .navigationTitle(viewStore.navigationTitle)
      .toolbar { toolbar(viewStore: viewStore) }
      .searchable(
        text: .constant(""),
        placement: .navigationBarDrawer(displayMode: .always)
      )
      .environment(\.isHidingFolderImages, viewStore.isHidingFolderImages)
      //      } destination: { state in
      //        switch state {
      //        case .folder:
      //          CaseLet(
      //            /FoldersReducer.PathReducer.State.folder,
      //             action: FoldersReducer.PathReducer.Action.folder
      //          ) {
      //            FolderView(store: $0)
      //          }
      //        case .recipe:
      //          CaseLet(
      //            /FoldersReducer.PathReducer.State.recipe,
      //             action: FoldersReducer.PathReducer.Action.recipe
      //          ) {
      //            RecipeView(store: $0)
      //          }
      //        }
      //      }
    }
  }
}

extension FoldersView {
  @ToolbarContentBuilder
  func toolbar(viewStore: ViewStoreOf<FoldersReducer>) -> some ToolbarContent {
      if viewStore.isEditing {
        ToolbarItemGroup(placement: .primaryAction) {
          Button("Done") {
            viewStore.send(.doneButtonTapped, animation: .default)
          }
        }
        
        ToolbarItemGroup(placement: .navigationBarLeading) {
          Button(viewStore.hasSelectedAll ? "Deselect All" : "Select All") {
            viewStore.send(.selectAllButtonTapped, animation: .default)
          }
        }
        
        ToolbarItemGroup(placement: .bottomBar) {
          Button("Move") {
//            viewStore.send(.moveSelectedButtonTapped, animation: .default)
          }
          .disabled(viewStore.selection.isEmpty)
          Spacer()
          Button("Delete") {
//            viewStore.send(.deleteSelectedButtonTapped, animation: .default)
          }
          .disabled(viewStore.selection.isEmpty)
        }
      }
      else {
        ToolbarItemGroup(placement: .primaryAction) {
          Menu {
            Button {
              viewStore.send(.selectFoldersButtonTapped, animation: .default)
            } label: {
              Label("Select Folders", systemImage: "checkmark.circle")
            }
            Button {
              viewStore.send(.hideImagesButtonTapped, animation: .default)
            } label: {
              Label(viewStore.isHidingFolderImages ? "Unhide Images" : "Hide Images", systemImage: "photo.stack")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
          .accentColor(.primary)
        }
      }
    }
}

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var folders: IdentifiedArrayOf<Folder>
    var isHidingFolderImages: Bool = false
    @BindingState var isEditing = false
    @BindingState var selection = Set<Folder.ID>()
 
    var hasSelectedAll: Bool {
      selection.count == folders.count
    }
    
    var navigationTitle: String {
      isEditing && selection.count > 0 ? "\(selection.count) Selected": "Folders"
    }
  }
  
  enum Action: Equatable, BindableAction {
    case selectFoldersButtonTapped
    case doneButtonTapped
    case selectAllButtonTapped
    case hideImagesButtonTapped
    case folderSelectionTapped(Folder.ID)
    case folderTapped(Folder.ID)
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .selectFoldersButtonTapped:
        state.isEditing = true
        return .none
        
      case .doneButtonTapped:
        state.isEditing = false
        state.selection = []
        return .none
        
      case .selectAllButtonTapped:
        state.selection = state.hasSelectedAll ? [] : .init(state.folders.map(\.id))
        return .none
        
      case .hideImagesButtonTapped:
        state.isHidingFolderImages.toggle()
        return .none
        
      case let .folderSelectionTapped(id):
        guard state.folders[id: id] != nil else { return .none }
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        return .none
        
      case let .folderTapped(id):
        guard let folder = state.folders[id: id] else { return .none }
        state.path.append(.folder(.init(folder: folder)))
        return .none
        
      case .binding:
        return .none
        
        
      case let .path(action):
        switch action {
        case let .element(id: stackID, action: .folder(.delegate(action))):
          switch action {
          case let .folderTapped(folderID):
            guard case let .folder(folder) = state.path[id: stackID],
                  let childFolder = folder.folder.folders[id: folderID]
            else { return .none }
            state.path.append(.folder(.init(folder: childFolder)))
            return .none
            
          case let .recipeTapped(recipeID):
            guard case let .folder(folder) = state.path[id: stackID],
                  let recipe = folder.folder.recipes[id: recipeID]
            else { return .none }
            state.path.append(.recipe(.init(recipe: recipe)))
            return .none
          }
          
        case .element:
          return .none
          
        default:
          return .none
        }
      }
    }
    .forEach(\.path, action: /Action.path) {
      PathReducer()
    }
  }
}

extension FoldersReducer {
  struct PathReducer: Reducer {
    enum State: Equatable {
      case folder(FolderReducer.State)
      case recipe(RecipeReducer.State)
    }
    
    enum Action: Equatable {
      case folder(FolderReducer.Action)
      case recipe(RecipeReducer.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: /State.folder, action: /Action.folder) {
        FolderReducer()
      }
      Scope(state: /State.recipe, action: /Action.recipe) {
        RecipeReducer()
      }
    }
  }
}

// MARK: - Preview
struct FoldersView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FoldersView(store: .init(
        initialState: .init(folders: .init(uniqueElements: Folder.longMock.folders)),
        reducer: FoldersReducer.init
      ))
    }
  }
}

