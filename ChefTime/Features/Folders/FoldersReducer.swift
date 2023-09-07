import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var systemAllFolder: FolderGridItemReducer.State
    var systemStandardFolder: FolderGridItemReducer.State
    var systemRecentlyDeletedFolder: FolderGridItemReducer.State
    var userFolders: IdentifiedArrayOf<FolderGridItemReducer.State> = []
    var isHidingFolderImages: Bool = false
    @BindingState var systemFoldersIsExpanded = true
    @BindingState var foldersIsExpanded = true
    @BindingState var isEditing = false
    @BindingState var selection = Set<FolderGridItemReducer.State.ID>()
    @PresentationState var alert: AlertState<AlertAction>?
    
    var hasSelectedAll: Bool {
      selection.count == userFolders.count
    }
    
    var navigationTitle: String {
      isEditing && selection.count > 0 ? "\(selection.count) Selected": "Folders"
    }
    
    init(
      path: StackState<PathReducer.State> = .init(),
      isHidingFolderImages: Bool = false,
      systemFoldersIsExpanded: Bool = true,
      foldersIsExpanded: Bool = true,
      isEditing: Bool = false,
      alert: AlertState<AlertAction>? = nil
    ) {
      @Dependency(\.uuid) var uuid
      self.path = path
      self.isHidingFolderImages = isHidingFolderImages
      self.systemFoldersIsExpanded = systemFoldersIsExpanded
      self.foldersIsExpanded = foldersIsExpanded
      self.isEditing = isEditing
      self.alert = alert
      self.systemAllFolder = .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), folderType: .systemAll))
      self.systemStandardFolder = .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), folderType: .systemStandard))
      self.systemRecentlyDeletedFolder = .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), folderType: .systemRecentlyDeleted))
      self.userFolders = []
    }
  }
  
  enum Action: Equatable, BindableAction {
    case task
    case loadFolderSuccess(Folder)
    case selectFoldersButtonTapped
    case doneButtonTapped
    case selectAllButtonTapped
    case hideImagesButtonTapped
    case moveSelectedButtonTapped
    case deleteSelectedButtonTapped
    case folderSelectionTapped(FolderGridItemReducer.State.ID)
    case userFolder(FolderGridItemReducer.State.ID, FolderGridItemReducer.Action)
    case systemAllFolder(FolderGridItemReducer.Action)
    case systemStandardFolder(FolderGridItemReducer.Action)
    case systemRecentlyDeletedFolder(FolderGridItemReducer.Action)
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case alert(PresentationAction<AlertAction>)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.database) var database
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .task:
        return .run { send in
          for await folder in database.fetchAllFolders() {
            await send(.loadFolderSuccess(folder), animation: .default)
          }
        }
        
        // TODO: Make sure you check the unique folder types for this...
      case let .loadFolderSuccess(folder):
        state.userFolders.append(.init(id: .init(rawValue: uuid()), folder: folder))
        return .none
        
      case .selectFoldersButtonTapped:
        state.isEditing = true
        return .none
        
      case .doneButtonTapped:
        state.isEditing = false
        state.selection = []
        return .none
        
      case .selectAllButtonTapped:
        state.selection = state.hasSelectedAll ? [] : .init(state.userFolders.map(\.id))
        return .none
        
      case .hideImagesButtonTapped:
        state.isHidingFolderImages.toggle()
        return .none
        
      case .moveSelectedButtonTapped:
        return .none
        
      case .deleteSelectedButtonTapped:
        state.alert = .delete
        return .none
        
      case let .folderSelectionTapped(id):
        guard state.userFolders[id: id] != nil else { return .none }
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        return .none
        
        
      case let .userFolder(id, .delegate(action)):
        return .none
        
      case let .systemAllFolder(.delegate(action)):
        return .none
        
      case let .systemStandardFolder(.delegate(action)):
        return .none
        
      case let .systemRecentlyDeletedFolder(.delegate(action)):
        return .none
        
      case .userFolder, .systemAllFolder, .systemStandardFolder, .systemRecentlyDeletedFolder:
        return .none
        
//      case let .systemFolderTapped(folderType):
//        if let newPathElement: PathReducer.State = {
//          switch folderType {
//          case .systemAll: return .folder(.init(folder: state.systemStandardFolder.folder))
//          case .systemStandard: return .folder(.init(folder: state.systemStandardFolder.folder))
//          case .systemRecentlyDeleted: return .folder(.init(folder: state.systemRecentlyDeletedFolder.folder))
//          case .user: return nil
//          }
//        }() {
//          state.path.append(newPathElement)
//        }
//        return .none
//
//      case let .folderTapped(id):
//        guard let folder = state.userFolders[id: id] else { return .none }
//        state.path.append(.folder(.init(folder: folder.folder)))
//        return .none
        
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
        
      case let .alert(.presented(action)):
        switch action {
        case .cancelButtonTapped:
          return .none
          
        case .confirmDeleteButtonTapped:
          state.userFolders = state.userFolders.filter({
            !state.selection.contains($0.id)
          })
          return .none
        }
        
      case .alert(.dismiss):
        state.alert = nil
        return .none
        
      case .alert:
        return .none
      }
    }
    .forEach(\.path, action: /Action.path) {
      PathReducer()
    }
    .forEach(\.userFolders, action: /Action.userFolder) {
      FolderGridItemReducer()
    }
    
    Scope(state: \.systemAllFolder, action: /Action.systemAllFolder) {
      FolderGridItemReducer()
    }
    
    Scope(state: \.systemStandardFolder, action: /Action.systemStandardFolder) {
      FolderGridItemReducer()
    }
    
    Scope(state: \.systemRecentlyDeletedFolder, action: /Action.systemRecentlyDeletedFolder) {
      FolderGridItemReducer()
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

extension FoldersReducer {
  enum AlertAction: Equatable {
    case cancelButtonTapped
    case confirmDeleteButtonTapped
  }
}

extension AlertState where Action == FoldersReducer.AlertAction {
  static let delete = Self(
    title: {
      TextState("Delete")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteButtonTapped) {
        TextState("Yes")
      }
      ButtonState(role: .cancel, action: .cancelButtonTapped) {
        TextState("No")
      }
    },
    message: {
      TextState("Are you sure you want to delete the selected items?")
    }
  )
}

struct Previews_FoldersReducer_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FoldersView(store: .init(
        initialState: .init(),
        reducer: FoldersReducer.init
      ))
    }
  }
}
