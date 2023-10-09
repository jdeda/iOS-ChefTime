import ComposableArchitecture
import SwiftUI
import Tagged

/// Right now in our app, we are mixing many differnt layers of types.
/// Our FolderReducer is not powered whatsoever by a Folder. Instead, it is powered by several other pieces of data.
/// We need to have a more complex state representation here to create child features easily.
/// Yet I believe here is where a weakness of TCA lies.
/// We cannot derive values on the fly. Well, not easily. We must have the exact type for the state of the child feature.
///
/// Anway, we have a CoreModel <--> Model <--> ViewModel
/// This is a lot of conversion logic and copying. This is inefficient and very burdemsome.

//extension FolderReducer {
//  struct FolderViewModel {
//    var name: String {
//      didSet {
//        folder.name = name
//      }
//    }
//    var folders: FolderSectionReducer.State {
//      didSet {
//        folder.folders = .init(uniqueElements: folders.folders.map(\.folder))
//      }
//    }
//    var recipes: RecipeSectionReducer.State {
//      didSet {
//        folder.recipes = .init(uniqueElements: recipes.recipes.map(\.recipe))
//      }
//    }
//
//    var folder: Folder
//  }
//}

// MARK: - Not sure what is a good pattern for naming this.
/// Our challenge is we have three layers of models:
/// 1. Model -- the model we think immediately and care about persistence
/// 2. ViewModel -- this is the view's extrapolation of the model to make the view work. by work i mean represent a state
/// that allows the view and state amangement architecture work. using the model for example may not be descriptive
/// or usable -- i.e. i have a complex view with complex state, an array of recipes to work on isn't going to cut it
///
/// so the question would arise: do we need to synchronize the state of the view that represents a model, to an instance of that model?
/// well you'd probably consider it. that way we are synchronized. if the view shows us our folder or recipe looks different and we did work, then
/// our db better reflect that! and if something changed in our db, then our view better reflect that!
///

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
      self.folderSection = .init(title: "Folders", folders: folder.folders)
      self.recipeSection = .init(title: "Folders", recipes: folder.recipes)
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
//    Scope(state: \.folderModel.folders, action: /Action.folders) {
//      FolderSectionReducer()
//    }
//    Scope(state: \.folderModel.recipes, action: /Action.recipes) {
//      RecipeSectionReducer()
//    }
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

