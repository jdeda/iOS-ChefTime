import ComposableArchitecture
import SwiftUI
import Tagged

// MARK: - Reducer
struct FolderReducer: Reducer {
  struct State: Equatable {
    var scrollViewIndex: Int = 1
    var folders: FolderSectionReducer.State
    var recipes: RecipeSectionReducer.State
    var isHidingFolderImages: Bool = false
    var isEditing: Section? = nil
    @PresentationState var alert: AlertState<AlertAction>?
    
    var hasSelectedAll: Bool {
      false
    }
    
    var navigationTitle: String {
      "yay"
    }
  }
  
  enum Section: Equatable {
    case folders
    case recipes
  }
  
  enum Action: Equatable, BindableAction {
    case hideImagesButtonTapped
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
  }
  
  @Dependency(\.database) var database
  @Dependency(\.uuid) var uuid
  
  var body: some Reducer<FolderReducer.State, FolderReducer.Action> {
    BindingReducer()
    Reduce<FolderReducer.State, FolderReducer.Action> { state, action in
      switch action {
      case .hideImagesButtonTapped:
        return .none
        
      case .selectFoldersButtonTapped:
        return .none
        
      case .selectRecipesButtonTapped:
        return .none
        
      case .doneButtonTapped:
        return .none
        
      case .selectAllButtonTapped:
        return .none
        
      case .moveSelectedButtonTapped:
        return .none
        
      case .deleteSelectedButtonTapped:
        return .none
        
      case .newFolderButtonTapped:
        return .none
        
      case .newRecipeButtonTapped:
        return .none
        
      case let .folders(.delegate(action)):
        return .none
        
      case let .recipes(.delegate(action)):
        return .none
        
      case let .alert(.presented(action)):
        return .none
        
      case .binding, .folders, .recipes, .alert:
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
    case cancelButtonTapped
    case confirmDeleteButtonTapped
  }
}

// MARK: - AlertState
extension AlertState where Action == FolderReducer.AlertAction {
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

// MARK: - Previews
struct Previews_FolderReducer_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      let folder  = FolderGridItemReducer.State(id: .init(), folder: Folder.longMock)
      FolderView(store: .init(
        initialState: .init(
          folders: .init(title: "Folders", folders: .init(uniqueElements: folder.folder.folders.map {
            .init(id: .init(), folder: $0)
          })),
          recipes: .init(title: "Recipes", recipes: .init(uniqueElements: folder.folder.recipes.map {
            .init(id: .init(), recipe: $0)
          }))
        ),
        reducer: FolderReducer.init
      ))
    }
  }
}

