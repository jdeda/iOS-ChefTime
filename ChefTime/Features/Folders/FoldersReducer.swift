import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var systemAllFolder = Folder(id: .init(), name: "All", folderType: .systemAll)
    var systemStandardFolder = Folder(id: .init(), name: "Recipes", folderType: .systemStandard)
    var systemRecentlyDeletedFolder = Folder(id: .init(), name: "Recently Deleted", folderType: .systemRecentlyDeleted)
    var userFolders: IdentifiedArrayOf<Folder>
    var isHidingFolderImages: Bool = false
    @BindingState var systemFoldersIsExpanded = true
    @BindingState var foldersIsExpanded = true
    @BindingState var isEditing = false
    @BindingState var selection = Set<Folder.ID>()
    @PresentationState var alert: AlertState<AlertAction>?
    
    var hasSelectedAll: Bool {
      selection.count == userFolders.count
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
    case moveSelectedButtonTapped
    case deleteSelectedButtonTapped
    case systemFolderTapped(Folder.FolderType)
    case folderSelectionTapped(Folder.ID)
    case folderTapped(Folder.ID)
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case alert(PresentationAction<AlertAction>)
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
        
      case let .systemFolderTapped(folderType):
        if let newPathElement: PathReducer.State = {
          switch folderType {
          case .systemAll: return .folder(.init(folder: state.systemStandardFolder))
          case .systemStandard: return .folder(.init(folder: state.systemStandardFolder))
          case .systemRecentlyDeleted: return .folder(.init(folder: state.systemRecentlyDeletedFolder))
          case .user: return nil
          }
        }() {
          state.path.append(newPathElement)
        }
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
        
      case let .folderTapped(id):
        guard let folder = state.userFolders[id: id] else { return .none }
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
        initialState: .init(
          userFolders: .init(uniqueElements: Folder.longMock.folders)
        ),
        reducer: FoldersReducer.init
      ))
    }
  }
}
