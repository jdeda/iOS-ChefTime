import ComposableArchitecture

@Reducer
struct FolderReducer {
  struct State: Equatable {
    var didLoad = false
    @BindingState var folder: Folder
    var folderSection: FolderSectionReducer.State {
      didSet { self.folder.folders = self.folderSection.folders.map(\.folder) }
    }
    var recipeSection: RecipeSectionReducer.State {
      didSet { self.folder.recipes = self.recipeSection.recipes.map(\.recipe) }
    }
    var isHidingImages: Bool = false
    var scrollViewIndex: Int = 1
    var editStatus: Section?
    @PresentationState var alert: AlertState<Action.AlertAction>?
    
    // TODO: - What to do with the dates here?
    init(folderID: Folder.ID) {
      self.init(folder: .init(id: folderID, creationDate: .init(), lastEditDate: .init()))
    }
    
    init(folder: Folder) {
      print("\(folder.id.uuidString)")
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
  
  enum Action: Equatable, BindableAction {
    case setDidLoad(Bool)
    case task
    case fetchFolderSuccess(Folder)
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
    case binding(BindingAction<State>)

    case delegate(DelegateAction)
    @CasePathable
    @dynamicMemberLookup
    enum DelegateAction: Equatable {
      case addNewFolderDidComplete(Folder.ID)
      case addNewRecipeDidComplete(Recipe.ID)
      case folderTapped(Folder.ID)
      case recipeTapped(Recipe.ID)
      case folderUpdated(FolderReducer.State)
    }

    case alert(PresentationAction<AlertAction>)
    @CasePathable
    enum AlertAction: Equatable {
      case confirmDeleteSelectedButtonTapped
    }
  }
  
  @CasePathable
  enum Section: Equatable {
    case folders
    case recipes
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.date) var date
  @Dependency(\.continuousClock) var clock
  @Dependency(\.database) var database
  
  var body: some Reducer<FolderReducer.State, FolderReducer.Action> {
    CombineReducers {
      Scope(state: \.folderSection, action: \.folders, child: FolderSectionReducer.init)
      Scope(state: \.recipeSection, action: \.recipes, child: RecipeSectionReducer.init)
      BindingReducer()
      Reduce<FolderReducer.State, FolderReducer.Action> { state, action in
        switch action {
        case let .setDidLoad(didLoad):
          state.didLoad = didLoad
          return .none
          
        case .task:
          guard !state.didLoad else { return .none }
          let folder = state.folder
          return .run { send in
            if let newFolder = await self.database.retrieveFolder(folder.id) {
              await send(.fetchFolderSuccess(newFolder))
            }
            else {
              // TODO: - Handle DB errors in future
              try! await self.database.createFolder(folder)
            }
          }
          .concatenate(with: .send(.setDidLoad(true)))
          
        case let .fetchFolderSuccess(newFolder):
          dump(newFolder)
          state = .init(folder: newFolder)
          return .none
          
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
          let newFolder = Folder(
            id: .init(rawValue: uuid()),
            name: "New Untitled Folder",
            creationDate: date(),
            lastEditDate: date()
          )
          state.folder.folders.append(newFolder)
          state.folderSection.folders.append(.init(folder: newFolder))
          return .send(.delegate(.addNewFolderDidComplete(newFolder.id)), animation: .default)
          
        case .newRecipeButtonTapped:
          let newRecipe = Recipe(
            id: .init(rawValue: uuid()),
            name: "New Untitled Recipe",
            creationDate: date(),
            lastEditDate: date()
          )
          state.folder.recipes.append(newRecipe)
          state.recipeSection.recipes.append(.init(recipe: newRecipe))
          return .send(.delegate(.addNewRecipeDidComplete(newRecipe.id)), animation: .default)
          
        case let .folders(.delegate(action)):
          switch action {
            
          case let .folderTapped(id):
            return .send(.delegate(.folderTapped(id)))
          }
          
        case let .recipes(.delegate(action)):
          switch action {
          case let .recipeTapped(id):
            return .send(.delegate(.recipeTapped(id)))
          }
          
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
    }
    .onChange(of: \.folder) { _, newFolder in // TODO: Does newFolder get copied every call?
      Reduce { _, _ in
          .run { _ in
            enum FolderUpdateID: Hashable { case debounce }
            try await withTaskCancellation(id: FolderUpdateID.debounce, cancelInFlight: true) {
              try await self.clock.sleep(for: .seconds(1))
              print("Updated folder \(newFolder.id.uuidString)")
              // TODO: - Handle DB errors in future
              try! await database.updateFolder(newFolder)
            }
          }
      }
    }
  }
}

extension AlertState where Action == FolderReducer.Action.AlertAction {
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
