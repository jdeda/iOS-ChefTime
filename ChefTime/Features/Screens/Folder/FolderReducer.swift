import ComposableArchitecture
import SwiftUI
import Tagged

// MARK: - Reducer
struct FolderReducer: Reducer {
  struct State: Equatable {
    @BindingState var folder: Folder
    var folderSection: FolderSectionReducer.State
    var recipeSection: RecipeSectionReducer.State
    var isHidingImages: Bool = false
    var scrollViewIndex: Int = 1
    var editStatus: Section?
    @PresentationState var alert: AlertState<AlertAction>?
    
    init(folder: Folder) {
      self.folder = folder
      self.folderSection = .init(folders: folder.folders)
      self.recipeSection = .init(recipes: folder.recipes)
      self.isHidingImages = false
      self.editStatus = nil
      self.scrollViewIndex = 1
      self.alert = nil
    }
    
    var hasSelectedAll: Bool {
      switch self.editStatus {
      case .folders: return folderSection.selection.count == folderSection.folders.count
      case .recipes: return recipeSection.selection.count == recipeSection.recipes.count
      case .none: return false
      }
    }
    
    var navigationTitle: String {
      switch self.editStatus {
      case .folders: return hasSelectedAll ? "\(folderSection.selection.count) Folders Selected" : folder.name
      case .recipes: return hasSelectedAll ? "\(recipeSection.selection.count) Recipes Selected" : folder.name
      case .none: return folder.name
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
        state.editStatus = .folders
        state.folderSection.isExpanded = true
        state.recipeSection.isExpanded = false
        return .none
        
      case .selectRecipesButtonTapped:
        state.editStatus = .recipes
        state.folderSection.isExpanded = false
        state.recipeSection.isExpanded = true
        return .none
        
      case .doneButtonTapped:
        state.editStatus = nil
        state.folderSection.selection = []
        state.recipeSection.selection = []
        state.folderSection.isExpanded = true
        state.recipeSection.isExpanded = true
        return .none
        
      case .selectAllButtonTapped:
        switch state.editStatus {
        case .folders:
          state.folderSection.selection = .init(
            state.hasSelectedAll ? [] : state.folderSection.folders.map(\.id)
          )
          break
        case .recipes:
          state.recipeSection.selection = .init(
            state.hasSelectedAll ? [] : state.recipeSection.recipes.map(\.id)
          )
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
        state.folderSection.folders.append(.init(folder: .init(id: .init(rawValue: uuid()), name: "New Untitled Folder")))
        return .send(.delegate(.addNewFolderButtonTappedDidComplete(id)), animation: .default)
        
      case .newRecipeButtonTapped:
        let id = RecipeGridItemReducer.State.ID(rawValue: uuid())
        state.recipeSection.recipes.append(.init(recipe: .init(id: .init(rawValue: uuid()), name: "New Untitled Recipe")))
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
          switch state.editStatus {
          case .folders:
            state.folderSection.folders = state.folderSection.folders.filter { !state.folderSection.selection.contains($0.id) }
            break
          case .recipes:
            state.recipeSection.recipes = state.recipeSection.recipes.filter { !state.recipeSection.selection.contains($0.id) }
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
    .onChange(of: { $0 }) { _, newValue in
      Reduce { _, _ in
          .send(.delegate(.folderUpdated(newValue)))
      }
    }
    Scope(state: \.folderSection, action: /Action.folders) {
      FolderSectionReducer()
    }
    Scope(state: \.recipeSection, action: /Action.recipes) {
      RecipeSectionReducer()
    }
  }
}

// MARK: - DelegateAction
extension FolderReducer {
  enum DelegateAction: Equatable {
    case addNewFolderButtonTappedDidComplete(FolderGridItemReducer.State.ID)
    case addNewRecipeButtonTappedDidComplete(RecipeGridItemReducer.State.ID)
    case folderUpdated(FolderReducer.State)
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
      FolderView(store: .init(
        initialState: .init(folder: Folder.longMock),
        reducer: FolderReducer.init
      ))
    }
  }
}

