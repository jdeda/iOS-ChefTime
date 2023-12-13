import ComposableArchitecture
import Log4swift

// TODO: MAKE SURE PARENT IDs work!
struct FolderReducer: Reducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    @BindingState var folder: Folder
    var folderSection: GridSectionReducer<Folder.ID>.State
    var recipeSection: GridSectionReducer<Recipe.ID>.State
    var isHidingImages: Bool = false
    var editStatus: Section?
    @PresentationState var destination: DestinationReducer.State?
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
      self.destination = nil
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
    case renameFolderButtonTapped
    case acceptFolderNameButtonTapped(String)
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

    case destination(PresentationAction<DestinationReducer.Action>)
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
            state.folderSection.gridItems.ids.forEach { id in
              state.folderSection.gridItems[id: id]!.isSelected = state.hasSelectedAll
            }
            break
          case .recipes:
            state.recipeSection.selection = .init(
              state.hasSelectedAll ? [] : state.recipeSection.gridItems.map(\.id)
            )
            state.recipeSection.gridItems.ids.forEach { id in
              state.recipeSection.gridItems[id: id]!.isSelected = state.hasSelectedAll
            }
            break
          case .none:
            break
          }
          return .none
          
        case .deleteSelectedButtonTapped:
          state.destination = .alert(.delete)
          return .none
          
            // TODO: XXX Persist here directly
        case .newFolderButtonTapped:
          let newFolder = Folder(
            id: .init(rawValue: uuid()),
            parentFolderID: state.folder.id,
            name: "New Untitled Folder",
            creationDate: date(),
            lastEditDate: date()
          )
          state.folder.folders.append(newFolder)
          state.folderSection.gridItems.append(.init(newFolder))
          return .run { send in
            try! await self.database.createFolder(newFolder)
            await send(.delegate(.navigateToFolder(newFolder.id)), animation: .default)
          }
          
          // TODO: XXX Persist here directly
        case .newRecipeButtonTapped:
          let newRecipe = Recipe(
            id: .init(rawValue: uuid()),
            parentFolderID: state.folder.id,
            name: "New Untitled Recipe",
            creationDate: date(),
            lastEditDate: date()
          )
          state.folder.recipes.append(newRecipe)
          state.recipeSection.gridItems.append(.init(newRecipe))
          return .run { send in
            try! await self.database.createRecipe(newRecipe)
            await send(.delegate(.navigateToRecipe(newRecipe.id)), animation: .default)
          }
          
        case .renameFolderButtonTapped:
          state.destination = .renameFolderAlert
          return .none
          
        case let .acceptFolderNameButtonTapped(newName):
          state.destination = nil
          state.folder.name = newName
          return .run { [folder = state.folder] send in
            try! await database.updateFolder(folder)
          }
          
        case let .folderSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.navigateToFolder(id)))
          }
          
          // TODO: XXX Persist here directly
        case .folderSection:
          // Here, we simply accumulate values.
          // The GridSection feature can only delete and edit items (name and images),
          // we assume here that is what happens, we just edit or skip the value
          // MARK: - Force unwrapping, because if IDs don't match something is very wrong.
          let oldFolders = state.folder.folders
          let newIDs = state.folderSection.gridItems.ids
          state.folder.folders = state.folder.folders.reduce(into: []) { partial, folder in
            if newIDs.contains(folder.id) {
              var mutatedFolder = folder
              mutatedFolder.name = state.folderSection.gridItems[id: folder.id]!.name
              mutatedFolder.imageData = state.folderSection.gridItems[id: folder.id]!.photos.photos.first
              partial.append(mutatedFolder)
            }
          }
          return self.persistFolders(oldFolders: oldFolders, newFolders: state.folder.folders)
          
        case let .recipeSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.navigateToRecipe(id)))
          }
          
          // TODO: XXX Persist here directly
        case .recipeSection:
          // Here, we simply accumulate values.
          // The GridSection feature can only delete and edit strictly the name,
          // NOT the images in the case of a recipe.
          // we assume here that is what happens, we just edit or skip the value
          // MARK: - Force unwrapping, because if IDs don't match something is very wrong.
          let oldRecipes = state.folder.recipes
          let newIDs = state.recipeSection.gridItems.ids
          state.folder.recipes = state.folder.recipes.reduce(into: []) { partial, folder in
            if newIDs.contains(folder.id) {
              var mutatedFolder = folder
              mutatedFolder.name = state.recipeSection.gridItems[id: folder.id]!.name
              partial.append(mutatedFolder)
            }
          }
          return self.persistRecipes(oldRecipes: oldRecipes, newRecipes: state.folder.recipes)


        case let .destination(.presented(.alert(action))):
          switch action {
            // TODO: XXX Persist here directly
          case .confirmDeleteSelectedButtonTapped:
            switch state.editStatus {
            case .folders:
              let deletionIDs = state.folderSection.selection
              state.folderSection.gridItems = state.folderSection.gridItems.filter {
                !deletionIDs.contains($0.id)
              }
              state.folderSection.selection = []
              return .run { send in
                for id in deletionIDs {
                  try! await self.database.deleteFolder(id)
                }
              }
            case .recipes:
              let deletionIDs = state.recipeSection.selection
              state.recipeSection.gridItems = state.recipeSection.gridItems.filter {
                !deletionIDs.contains($0.id)
              }
              state.recipeSection.selection = []
              return .run { send in
                for id in deletionIDs {
                  try! await self.database.deleteRecipe(id)
                }
              }
            case .none:
              return .none
            }
          }
          
        case .destination(.dismiss):
          state.destination = nil
          return .none
          
          
        case let .search(.delegate(.searchResultTapped(id))):
          return .send(.delegate(.navigateToRecipe(id)))
          
        case .binding, .destination, .search, .delegate:
          return .none
        }
      }
      .ifLet(\.$destination, action: /FolderReducer.Action.destination) {
        DestinationReducer()
      }
    }
    
    .signpost()
  }
}

extension FolderReducer {
  struct DestinationReducer: Reducer {
    enum State: Equatable {
      case alert(AlertState<Action.AlertAction>)
      case renameFolderAlert
    }
    
    enum Action: Equatable {
      case renameFolderAlert
      case alert(AlertAction)
      enum AlertAction: Equatable {
        case confirmDeleteSelectedButtonTapped
      }
    }
    
    var body: some ReducerOf<Self> {
      EmptyReducer()
    }
  }
}

extension FolderReducer {
  func persistFolders(
    oldFolders: IdentifiedArrayOf<Folder>,
    newFolders: IdentifiedArrayOf<Folder>
  ) -> Effect<Action> {
    let removeDuplicates = oldFolders == newFolders
    guard !removeDuplicates else { return .none }
    return .run { _ in
      enum UserFoldersUpdateID: Hashable { case debounce }
      try await withTaskCancellation(id: UserFoldersUpdateID.debounce, cancelInFlight: true) {
        // TODO: - Handle DB errors in future
        try await self.clock.sleep(for: .seconds(1))
        for updatedFolder in newFolders.intersectionByID(oldFolders).filter({ newFolders[id: $0.id] != oldFolders[id: $0.id] }) {
          try! await self.database.updateFolder(updatedFolder)
          Log4swift[Self.self].info("Updated folder \(updatedFolder.id.uuidString)")
        }
        for addedFolder in newFolders.symmetricDifferenceByID(oldFolders) {
          try! await self.database.createFolder(addedFolder)
          Log4swift[Self.self].info("Created folder \(addedFolder.id.uuidString)")
        }
        for removedFolder in oldFolders.symmetricDifferenceByID(newFolders) {
          try! await self.database.deleteFolder(removedFolder.id)
          Log4swift[Self.self].info("Deleted folder \(removedFolder.id.uuidString)")
        }
      }
    }
  }
  
  func persistRecipes(
    oldRecipes: IdentifiedArrayOf<Recipe>,
    newRecipes: IdentifiedArrayOf<Recipe>
  ) -> Effect<Action> {
    let removeDuplicates = oldRecipes == newRecipes
    guard !removeDuplicates else { return .none }
    return .run { _ in
      enum UserFoldersUpdateID: Hashable { case debounce }
      try await withTaskCancellation(id: UserFoldersUpdateID.debounce, cancelInFlight: true) {
        // TODO: - Handle DB errors in future
        try await self.clock.sleep(for: .seconds(1))
        for updatedRecipe in newRecipes.intersectionByID(oldRecipes).filter({ newRecipes[id: $0.id] != oldRecipes[id: $0.id] }) {
          try! await self.database.updateRecipe(updatedRecipe)
          Log4swift[Self.self].info("Updated folder \(updatedRecipe.id.uuidString)")
        }
        for addedRecipe in newRecipes.symmetricDifferenceByID(oldRecipes) {
          try! await self.database.createRecipe(addedRecipe)
          Log4swift[Self.self].info("Created folder \(addedRecipe.id.uuidString)")
        }
        for removedRecipe in oldRecipes.symmetricDifferenceByID(newRecipes) {
          try! await self.database.deleteRecipe(removedRecipe.id)
          Log4swift[Self.self].info("Deleted folder \(removedRecipe.id.uuidString)")
        }
      }
    }
  }
}

extension AlertState where Action == FolderReducer.DestinationReducer.Action.AlertAction {
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

