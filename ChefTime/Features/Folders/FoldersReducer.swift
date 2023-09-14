import ComposableArchitecture
import SwiftUI
import Tagged

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var scrollViewIndex: Int = 1
    var systemFoldersSection: FolderSectionReducer.State = .system
    var userFoldersSection: FolderSectionReducer.State = .user
    var isHidingImages: Bool = false
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
    case newFolderButtonTapped
    case newRecipeButtonTapped
    case userFoldersSection(FolderSectionReducer.Action)
    case systemFoldersSection(FolderSectionReducer.Action)
    case alert(PresentationAction<AlertAction>)
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
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
          state.systemFoldersSection.folders[1].folder = folder
          if (state.systemFoldersSection.folders[1].folder.imageData != nil),
             let imageData = folder.imageData {
            state.systemFoldersSection.folders[1].photos.photos = [imageData]
            state.systemFoldersSection.folders[1].photos.selection = imageData.id
          }
          // TODO: - Temporary and extremely dangerous.
          state.systemFoldersSection.folders[0].folder.imageData = folder.recipes[2].imageData.first!
          state.systemFoldersSection.folders[0].photos.photos = [folder.recipes[2].imageData.first!]
          state.systemFoldersSection.folders[0].photos.selection = folder.recipes[2].imageData.first!.id
          break
        case .systemRecentlyDeleted:
          state.systemFoldersSection.folders[2].folder = folder
          if (state.systemFoldersSection.folders[2].folder.imageData != nil),
             let imageData = folder.imageData {
            state.systemFoldersSection.folders[2].photos.photos = [imageData]
            state.systemFoldersSection.folders[2].photos.selection = imageData.id
          }
          break
        case .user:
          state.userFoldersSection.folders.append(.init(id: .init(), folder: folder))
          break
        }
        
        // Append the to the all folder.
        func flattenAllRecipes(_ folder: Folder) -> [Recipe] {
          var result: [Recipe] = folder.recipes.elements
          for folder in folder.folders {
            result += flattenAllRecipes(folder)
          }
          return result
        }
        
        let flattenedRecipes = flattenAllRecipes(folder)
        state.systemFoldersSection.folders[0].folder.recipes.append(contentsOf: flattenedRecipes)
        return .none
        
      case .selectFoldersButtonTapped:
        state.isEditing = true
        state.systemFoldersSection.isExpanded = false
        state.userFoldersSection.isExpanded = true
        //        state.scrollViewIndex = 1
        return .none
        
      case .doneButtonTapped:
        state.isEditing = false
        state.systemFoldersSection.isExpanded = true
        state.userFoldersSection.selection = []
        //        state.scrollViewIndex = 1
        return .none
        
      case .selectAllButtonTapped:
        state.userFoldersSection.selection = .init(
          state.hasSelectedAll ? [] : state.userFoldersSection.folders.map(\.id)
        )
        return .none
        
      case .hideImagesButtonTapped:
        state.isHidingImages.toggle()
        return .none
        
      case .moveSelectedButtonTapped:
        return .none
        
      case .deleteSelectedButtonTapped:
        state.alert = .delete
        return .none
        
      case .newFolderButtonTapped:
        let newFolder = FolderGridItemReducer.State(
          id: .init(rawValue: uuid()),
          folder: .init(
            id: .init(rawValue: uuid()),
            name: "New Untitled Folder",
            folderType: .user
          )
        )
        state.userFoldersSection.folders.append(newFolder)
        return .send(.delegate(.addNewFolderButtonTappedDidComplete(newFolder.id)), animation: .default)
        
      case .newRecipeButtonTapped:
        let newRecipe = Recipe(id: .init(rawValue: uuid()), name: "New Untitled Recipe")
        state.systemFoldersSection.folders[1].folder.recipes.append(newRecipe)
        return .send(.delegate(.addNewRecipeButtonTappedDidComplete(newRecipe.id)), animation: .default)
        
      case let .userFoldersSection(.delegate(action)):
        switch action {
        case let .folderTapped(id):
          guard let folder = state.userFoldersSection.folders[id: id]?.folder
          else { return .none }
          return .none
        }
        
      case let .systemFoldersSection(.delegate(action)):
        switch action {
        case let .folderTapped(id):
          guard let folder = state.systemFoldersSection.folders[id: id]?.folder
          else { return .none }
          return .none
        }
      case .binding:
        return .none
        
      case let .alert(.presented(action)):
        switch action {
        case .cancelButtonTapped:
          return .none
          
        case .confirmDeleteButtonTapped:
          state.userFoldersSection.folders = state.userFoldersSection.folders.filter {
            !state.userFoldersSection.selection.contains($0.id)
          }
          state.userFoldersSection.selection = []
          return .none
        }
        
      case .alert(.dismiss):
        state.alert = nil
        return .none
        
      case .alert, .systemFoldersSection, .userFoldersSection, .delegate:
        return .none
      }
    }
    Scope(state: \.systemFoldersSection, action: /Action.systemFoldersSection) {
      FolderSectionReducer()
    }
    Scope(state: \.userFoldersSection, action: /Action.userFoldersSection) {
      FolderSectionReducer()
    }
  }
}

// MARK: - AlertAction
extension FoldersReducer {
  enum DelegateAction: Equatable {
    case addNewFolderButtonTappedDidComplete(FolderGridItemReducer.State.ID)
    case addNewRecipeButtonTappedDidComplete(Recipe.ID)
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
      title: "System", folders: [
        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "All", folderType: .systemAll)),
        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "Standard", folderType: .systemStandard)),
        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "Recently Deleted", folderType: .systemRecentlyDeleted))
      ]
    )
  }()
  
  static let user = Self(title: "User", folders: [])
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

