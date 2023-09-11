import ComposableArchitecture
import SwiftUI
import Tagged

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var systemFoldersSection: FolderSectionReducer.State = .system
    var userFoldersSection: FolderSectionReducer.State = .user
    var isHidingFolderImages: Bool = false
    @BindingState var isEditing = false
    @PresentationState var alert: AlertState<AlertAction>?
    
    var hasSelectedAll: Bool {
      userFoldersSection.selection.count == userFoldersSection.folders.count
    }
    
    var navigationTitle: String {
      let value = isEditing && userFoldersSection.selection.count > 0
      return value ? "\(userFoldersSection.selection.count) Selected": "Folders"
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
    case userFoldersSection(FolderSectionReducer.Action)
    case systemFoldersSection(FolderSectionReducer.Action)
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case alert(PresentationAction<AlertAction>)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.database) var database
  @Dependency(\.uuid) var uuid
  
  var body: some Reducer<FoldersReducer.State, FoldersReducer.Action> {
    BindingReducer()
    Reduce<FoldersReducer.State, FoldersReducer.Action> { state, action in
      switch action {
      case .task:
        guard state.userFoldersSection.folders.isEmpty else { return .none }
        return .run { send in
          for await folder in database.fetchAllFolders() {
            await send(.loadFolderSuccess(folder), animation: .default)
          }
        }
        
        // MARK: - Assuming we have our systemFoldersSection setup correctly
      case let .loadFolderSuccess(folder):
        switch folder.folderType {
        case .systemAll:
          break
        case .systemStandard:
          state.systemFoldersSection.folders[1].folder.folders.append(folder)
          break
        case .systemRecentlyDeleted:
          state.systemFoldersSection.folders[2].folder.folders.append(folder)
          break
        case .user:
          state.userFoldersSection.folders.append(.init(id: .init(), folder: folder))
          break
        }
        return .none
        
      case .selectFoldersButtonTapped:
        state.isEditing = true
        return .none
        
      case .doneButtonTapped:
        state.isEditing = false
        state.userFoldersSection.selection = []
        return .none
        
      case .selectAllButtonTapped:
        state.userFoldersSection.selection = .init(
          state.hasSelectedAll ? [] : state.userFoldersSection.folders.map(\.id)
        )
        return .none
        
      case .hideImagesButtonTapped:
        state.isHidingFolderImages.toggle()
        return .none
        
      case .moveSelectedButtonTapped:
        return .none
        
      case .deleteSelectedButtonTapped:
        state.alert = .delete
        return .none
        
      case let .userFoldersSection(.delegate(action)):
        switch action {
        case let .folderTapped(id):
          guard let folder = state.userFoldersSection.folders[id: id]?.folder
          else { return .none }
          state.path.append(.folder(.init(folder: folder)))
          return .none
        }
        return .none
        
      case let .systemFoldersSection(.delegate(action)):
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
          //          state.userFolders = state.userFolders.filter({
          //            !state.selection.contains($0.id)
          //          })
          return .none
        }
        
      case .alert(.dismiss):
        state.alert = nil
        return .none
        
      case .alert, .systemFoldersSection, .userFoldersSection:
        return .none
      }
    }
    .forEach(\.path, action: /Action.path) {
      PathReducer()
    }
    Scope(state: \.systemFoldersSection, action: /Action.systemFoldersSection) {
      FolderSectionReducer()
    }
    Scope(state: \.userFoldersSection, action: /Action.userFoldersSection) {
      FolderSectionReducer()
    }
  }
}


// MARK: - PathReducer
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

// MARK: - AlertAction
extension FoldersReducer {
  enum AlertAction: Equatable {
    case cancelButtonTapped
    case confirmDeleteButtonTapped
  }
}

// MARK: - AlertState
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

// MARK: - FolderSectionReducer.State instances
extension FolderSectionReducer.State {
  static let system: Self = {
    @Dependency(\.uuid) var uuid
    return Self(
      folders: [
        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "All", folderType: .systemAll)),
        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "Standard", folderType: .systemStandard)),
        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "Recently Deleted", folderType: .systemRecentlyDeleted))
      ],
      title: "System"
    )
  }()
  
  static let user = Self(folders: [], title: "User")
}


// MARK: - Previews
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

