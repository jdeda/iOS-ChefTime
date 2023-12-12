import ComposableArchitecture
import Log4swift

// TODO: MAKE SURE PARENT IDs work!
struct FolderReducer: Reducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    @BindingState var folder: Folder
    var folderSection: GridSectionReducer<Folder.ID>.State {
      didSet {
        // Here, we simply accumulate values.
        // The GridSection feature can only delete and edit items (name and images),
        // we assume here that is what happens, we just edit or skip the value
        // MARK: - Force unwrapping, because if IDs don't match something is very wrong.
        let newIDs = self.folderSection.gridItems.ids
        self.folder.folders = self.folder.folders.reduce(into: []) { partial, folder in
          if newIDs.contains(folder.id) {
            var mutatedFolder = folder
            mutatedFolder.name = self.folderSection.gridItems[id: folder.id]!.name
            mutatedFolder.imageData = self.folderSection.gridItems[id: folder.id]!.photos.photos.first
            partial.append(folder)
          }
        }
      }
    }
    var recipeSection: GridSectionReducer<Recipe.ID>.State {
      didSet {
        // Here, we simply accumulate values.
        // The GridSection feature can only delete and edit strictly the name,
        // NOT the images in the case of a recipe.
        // we assume here that is what happens, we just edit or skip the value
        // MARK: - Force unwrapping, because if IDs don't match something is very wrong.
        let newIDs = self.recipeSection.gridItems.ids
        self.folder.recipes = self.folder.recipes.reduce(into: []) { partial, folder in
          if newIDs.contains(folder.id) {
            var mutatedFolder = folder
            mutatedFolder.name = self.recipeSection.gridItems[id: folder.id]!.name
            partial.append(folder)
          }
        }
      }
    }
    var isHidingImages: Bool = false
    var scrollViewIndex: Int = 1
    var editStatus: Section?
    @PresentationState var alert: AlertState<Action.AlertAction>?
    var search: SearchReducer.State
    
    // TODO: - What to do with the dates here?
    init(folderID: Folder.ID) {
      self.init(folder: .init(id: folderID, creationDate: .init(), lastEditDate: .init()))
    }
    
    init(folder: Folder) {
      print("\(folder.id.uuidString)")
      self.folder = folder
      self.folderSection = .init(title: "Folders", gridItems: folder.folders.map(GridItemReducer.State.init))
      self.recipeSection = .init(title: "Recipes", gridItems: folder.recipes.map(GridItemReducer.State.init))
      self.isHidingImages = false
      self.editStatus = nil
      self.scrollViewIndex = 1
      self.alert = nil
      self.search = .init(query: "")
    }
    
    var hasSelectedAll: Bool {
      switch self.editStatus {
      case .folders: return folderSection.selection.count == folderSection.gridItems.count
      case .recipes: return recipeSection.selection.count == recipeSection.gridItems.count
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
    
    var isHidingFolders: Bool {
      editStatus == .recipes || folderSection.gridItems.isEmpty
    }
    
    var isHidingRecipes: Bool {
      editStatus == .folders || recipeSection.gridItems.isEmpty
    }

  }
  
  enum Action: Equatable, BindableAction {
    case didLoad
    case task
    case fetchFolderSuccess(Folder)
    case toggleHideImagesButtonTapped
    case selectFoldersButtonTapped
    case selectRecipesButtonTapped
    case doneButtonTapped
    case selectAllButtonTapped
    case deleteSelectedButtonTapped
    case newFolderButtonTapped
    case newRecipeButtonTapped
    case folderSection(GridSectionReducer<Folder.ID>.Action)
    case recipeSection(GridSectionReducer<Recipe.ID>.Action)
    case search(SearchReducer.Action)
    case binding(BindingAction<State>)

    case delegate(DelegateAction)
    
    
    enum DelegateAction: Equatable {
      case navigateToFolder(Folder.ID)
      case navigateToRecipe(Recipe.ID)
      case folderUpdated(FolderReducer.State)
    }

    case alert(PresentationAction<AlertAction>)
    
    enum AlertAction: Equatable {
      case confirmDeleteSelectedButtonTapped
    }
  }
  
  
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
      Scope(state: \.folderSection, action: /FolderReducer.Action.folderSection) {
        GridSectionReducer()
      }
      Scope(state: \.recipeSection, action: /FolderReducer.Action.recipeSection) {
        GridSectionReducer()
      }
      Scope(state: \.search, action: /FolderReducer.Action.search) {
        SearchReducer()
      }
      BindingReducer()
      Reduce<FolderReducer.State, FolderReducer.Action> { state, action in
        switch action {
        case .didLoad:
          state.loadStatus = .didLoad
          return .none
          
        case .task:
          guard state.loadStatus == .didNotLoad else { return .none }
          state.loadStatus = .isLoading
          let folder = state.folder
          return .run { send in
            if let newFolder = await self.database.retrieveFolder(folder.id) {
              Log4swift[Self.self].info("fetchFolderSuccess...")
              await send(.fetchFolderSuccess(newFolder))
            }
            else {
              // TODO: - Handle DB errors in future
              Log4swift[Self.self].info("createFolder...")
              try! await self.database.createFolder(folder)
            }
            await send(.didLoad)
          }
          
        case let .fetchFolderSuccess(newFolder):
          // dump(newFolder)
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
          for id in state.folderSection.gridItems.ids {
            state.folderSection.gridItems[id: id]?.isSelected = false
          }
          for id in state.recipeSection.gridItems.ids {
            state.recipeSection.gridItems[id: id]?.isSelected = false
          }
          state.recipeSection.isExpanded = true
          return .none
          
        case .selectAllButtonTapped:
          switch state.editStatus {
          case .folders:
            state.folderSection.selection = .init(
              state.hasSelectedAll ? [] : state.folderSection.gridItems.map(\.id)
            )
            break
          case .recipes:
            state.recipeSection.selection = .init(
              state.hasSelectedAll ? [] : state.recipeSection.gridItems.map(\.id)
            )
            break
          case .none:
            break
          }
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
          state.folderSection.gridItems.append(.init(newFolder))
          return .send(.delegate(.navigateToFolder(newFolder.id)), animation: .default)
          
        case .newRecipeButtonTapped:
          let newRecipe = Recipe(
            id: .init(rawValue: uuid()),
            name: "New Untitled Recipe",
            creationDate: date(),
            lastEditDate: date()
          )
          state.folder.recipes.append(newRecipe)
          state.recipeSection.gridItems.append(.init(newRecipe))
          return .send(.delegate(.navigateToRecipe(newRecipe.id)), animation: .default)
          
        case let .folderSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.navigateToFolder(id)))
          }
          
        case let .recipeSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.navigateToRecipe(id)))
          }
          
        case let .alert(.presented(action)):
          switch action {
          case .confirmDeleteSelectedButtonTapped:
            switch state.editStatus {
            case .folders:
              state.folderSection.gridItems = state.folderSection.gridItems.filter { !state.folderSection.selection.contains($0.id) }
              break
            case .recipes:
              state.recipeSection.gridItems = state.recipeSection.gridItems.filter { !state.recipeSection.selection.contains($0.id) }
              break
            case .none:
              break
            }
            return .none
          }
          
        case .alert(.dismiss):
          state.alert = nil
          return .none
          
          
        case let .search(.delegate(.searchResultTapped(id))):
          return .send(.delegate(.navigateToRecipe(id)))
          
        case .binding, .folderSection, .recipeSection, .alert, .search, .delegate:
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
    .signpost()
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

private extension GridItemReducer.State where ID == Folder.ID {
  init(_ folder: Folder) {
    self.init(
      id: folder.id,
      name: folder.name, 
      description: "\(folder.recipes.count) Recipes",
      imageData: folder.imageData
    )
  }
}

private extension GridItemReducer.State where ID == Recipe.ID {
  init(_ recipe: Recipe) {
    self.init(
      id: recipe.id,
      name: recipe.name, 
      description: recipe.lastEditDate.formattedDate,
      imageData: recipe.imageData.first,
      enabledContextMenuActions: .init(arrayLiteral: .rename, .delete)
    )
  }
}

