import ComposableArchitecture
import SwiftUI
import Tagged

// MARK: - Reducer
struct FolderReducer: Reducer {
  struct State: Equatable {
    var scrollViewIndex: Int = 1
    var name: String
    var folders: FolderSectionReducer.State
    var recipes: RecipeSectionReducer.State
    var isHidingImages: Bool = false
    var isEditing: Section? = nil
    @PresentationState var alert: AlertState<AlertAction>?
    
    var hasSelectedAll: Bool {
      switch self.isEditing {
      case .folders: return folders.selection.count == folders.folders.count
      case .recipes: return recipes.selection.count == recipes.recipes.count
      case .none: return false
      }
    }
    
    var navigationTitle: String {
      switch self.isEditing {
      case .folders: return hasSelectedAll ? "\(folders.selection.count) Folders Selected" : name
      case .recipes: return hasSelectedAll ? "\(recipes.selection.count) Recipes Selected" : name
      case .none: return name
      }
    }
  }
  
  enum Section: Equatable {
    case folders
    case recipes
  }
  
  enum Action: Equatable, BindableAction {
    case toggleHideImagesButtonTapped
    case selectFoldersButtonTapped
    case selectRecipesButtonTapped
    case doneButtonTapped
    case selectAllButtonTapped
    case moveSelectedButtonTapped
    case deleteSelectedButtonTapped
    
    case newFolderButtonTapped
    case newRecipeButtonTapped
    
    case folders(FolderSectionReducer.Action)
    case recipes(RecipeSectionReducer.Action)
    case alert(PresentationAction<AlertAction>)
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some Reducer<FolderReducer.State, FolderReducer.Action> {
    BindingReducer()
    Reduce<FolderReducer.State, FolderReducer.Action> { state, action in
      switch action {
      case .toggleHideImagesButtonTapped:
        state.isHidingImages.toggle()
        return .none
        
      case .selectFoldersButtonTapped:
        state.isEditing = .folders
        state.folders.isExpanded = true
        state.recipes.isExpanded = false
        return .none
        
      case .selectRecipesButtonTapped:
        state.isEditing = .recipes
        state.folders.isExpanded = false
        state.recipes.isExpanded = true
        return .none
        
      case .doneButtonTapped:
        state.isEditing = nil
        state.folders.selection = []
        state.recipes.selection = []
        state.folders.isExpanded = true
        state.recipes.isExpanded = true
        return .none
        
      case .selectAllButtonTapped:
        switch state.isEditing {
        case .folders:
          state.folders.selection = .init(state.hasSelectedAll ? [] : state.folders.folders.map(\.id))
          break
        case .recipes:
          state.recipes.selection = .init(state.hasSelectedAll ? [] : state.recipes.recipes.map(\.id))
          break
        case .none:
          break
        }
        return .none
        
      case .moveSelectedButtonTapped:
        return .none
        
      case .deleteSelectedButtonTapped:
        state.alert = .delete
        return .none
        
      case .newFolderButtonTapped:
        let id = FolderGridItemReducer.State.ID(rawValue: uuid())
        state.folders.folders.append(.init(id: id, folder: .init(id: .init(rawValue: uuid()), name: "New Untitled Folder")))
        return .send(.delegate(.addNewFolderButtonTappedDidComplete(id)), animation: .default)
        
      case .newRecipeButtonTapped:
        let id = RecipeGridItemReducer.State.ID(rawValue: uuid())
        state.recipes.recipes.append(.init(id: id, recipe: .init(id: .init(rawValue: uuid()), name: "New Untitled Recipe")))
        return .send(.delegate(.addNewRecipeButtonTappedDidComplete(id)), animation: .default)
        
      case let .folders(.delegate(action)):
        switch action {
          
        case let .folderTapped(id):
          // TODO: Navigate
          return .none
        }
        return .none
        
      case let .alert(.presented(action)):
        switch action {
        case .confirmDeleteSelectedButtonTapped:
          switch state.isEditing {
          case .folders:
            state.folders.folders = state.folders.folders.filter { !state.folders.selection.contains($0.id) }
            break
          case .recipes:
            state.recipes.recipes = state.recipes.recipes.filter { !state.recipes.selection.contains($0.id) }
            break
          case .none:
            break
          }
          return .none
        }
        
        
      case .alert(.dismiss):
        state.alert = nil
        return .none
        
      case .binding, .folders, .recipes, .alert, .delegate:
        return .none
      }
    }
    Scope(state: \.folders, action: /Action.folders) {
      FolderSectionReducer()
    }
    Scope(state: \.recipes, action: /Action.recipes) {
      RecipeSectionReducer()
    }
  }
}

// MARK: - DelegateAction
extension FolderReducer {
  enum DelegateAction: Equatable {
    case addNewFolderButtonTappedDidComplete(FolderGridItemReducer.State.ID)
    case addNewRecipeButtonTappedDidComplete(RecipeGridItemReducer.State.ID)
  }
}

// MARK: - PathReducer
extension FolderReducer {
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
extension FolderReducer {
  enum AlertAction: Equatable {
    case confirmDeleteSelectedButtonTapped
  }
}

// MARK: - AlertState
extension AlertState where Action == FolderReducer.AlertAction {
  static let delete = Self(
    title: {
      TextState("Delete")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSelectedButtonTapped) {
        TextState("Yes")
      }
      ButtonState(role: .cancel) {
        TextState("No")
      }
    },
    message: {
      TextState("Are you sure you want to delete the selected items?")
    }
  )
}

// MARK: - Previews
struct Previews_FolderReducer_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      let folder  = FolderGridItemReducer.State(id: .init(), folder: Folder.longMock)
      FolderView(store: .init(
        initialState: .init(
          name: Folder.longMock.name,
          folders: .init(title: "Folders", folders: .init(uniqueElements: folder.folder.folders.prefix(3).map {
            .init(id: .init(), folder: $0)
          })),
          recipes: .init(title: "Recipes", recipes: .init(uniqueElements: folder.folder.recipes.prefix(3).map {
            .init(id: .init(), recipe: $0)
          }))
        ),
        reducer: FolderReducer.init
      ))
    }
  }
}

