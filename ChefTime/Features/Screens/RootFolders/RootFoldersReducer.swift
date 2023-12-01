import ComposableArchitecture

// TODO: Rename FoldersReduer to RootFoldersReducer
// TODO: Deal with seperation of systemFolders, specificSystemFolders, and userFolders.
@Reducer
struct RootFoldersReducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    var systemFolders: IdentifiedArrayOf<Folder>
    var userFolders: IdentifiedArrayOf<Folder>
    var systemFoldersSection: GridSectionReducer<Folder.ID>.State {
      didSet {
        // Here, we simply accumulate values.
        // The GridSection feature can only delete and edit items (name and images),
        // we assume here that is what happens, we just edit or skip the value
        // MARK: - Force unwrapping, because if IDs don't match something is very wrong.
        let newIDs = self.systemFoldersSection.gridItems.ids
        self.systemFolders = self.systemFolders.reduce(into: []) { partial, folder in
          if newIDs.contains(folder.id) {
            var mutatedFolder = folder
            mutatedFolder.name = self.systemFoldersSection.gridItems[id: folder.id]!.name
            mutatedFolder.imageData = self.systemFoldersSection.gridItems[id: folder.id]!.photos.photos.first
            partial.append(folder)
          }
        }
      }
    }
    var userFoldersSection: GridSectionReducer<Folder.ID>.State {
      didSet {
        // Here, we simply accumulate values.
        // The GridSection feature can only delete and edit items (name and images),
        // we assume here that is what happens, we just edit or skip the value
        // MARK: - Force unwrapping, because if IDs don't match something is very wrong.
        let newIDs = self.userFoldersSection.gridItems.ids
        self.userFolders = self.userFolders.reduce(into: []) { partial, folder in
          if newIDs.contains(folder.id) {
            var mutatedFolder = folder
            mutatedFolder.name = self.userFoldersSection.gridItems[id: folder.id]!.name
            mutatedFolder.imageData = self.userFoldersSection.gridItems[id: folder.id]!.photos.photos.first
            partial.append(folder)
          }
        }
      }
    }
    var scrollViewIndex: Int
    var isHidingImages: Bool
    @BindingState var isEditing: Bool
    @PresentationState var alert: AlertState<Action.AlertAction>?
    
    init(
      systemFolders: IdentifiedArrayOf<Folder> = [],
      userFolders: IdentifiedArrayOf<Folder> = []
    ) {
      self.systemFolders = systemFolders
      self.userFolders = userFolders
      self.systemFoldersSection = .init(title: "System", gridItems: systemFolders.map(GridItemReducer.State.init))
      self.userFoldersSection = .init(title: "User", gridItems: userFolders.map(GridItemReducer.State.init))
      self.scrollViewIndex = 1
      self.isHidingImages = false
      self.isEditing = false
      self.alert = nil
    }
    
    var hasSelectedAll: Bool {
      userFoldersSection.selection.count == userFoldersSection.gridItems.count
    }
    
    var navigationTitle: String {
      let value = isEditing && userFoldersSection.selection.count > 0
      return value ? "\(userFoldersSection.selection.count) Selected": "Folders"
    }
    
    var systemStandardFolderID: Folder.ID {
      self.systemFolders.first(where: { $0.folderType == .systemStandard })!.id
    }
  }
  
  enum Action: Equatable, BindableAction {
    case didLoad
    case task
    case fetchFoldersSuccess(IdentifiedArrayOf<Folder>)
    case selectFoldersButtonTapped
    case doneButtonTapped
    case selectAllButtonTapped
    case hideImagesButtonTapped
    case moveSelectedButtonTapped
    case deleteSelectedButtonTapped
    case newFolderButtonTapped
    case newRecipeButtonTapped
    case userFoldersSection(GridSectionReducer<Folder.ID>.Action)
    case systemFoldersSection(GridSectionReducer<Folder.ID>.Action)
    case binding(BindingAction<State>)
    
    case delegate(DelegateAction)
    @CasePathable
    @dynamicMemberLookup
    enum DelegateAction: Equatable {
      case addNewFolderDidComplete(Folder.ID)
      case addNewRecipeDidComplete(Recipe.ID)
      case userFolderTapped(Folder.ID)
      case systemFolderTapped(Folder.ID)
    }
    
    case alert(PresentationAction<AlertAction>)
    @CasePathable
    enum AlertAction: Equatable {
      case cancelButtonTapped
      case confirmDeleteButtonTapped
    }
  }
  
  @Dependency(\.database) var database
  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid
  @Dependency(\.date) var date
  
  var body: some Reducer<RootFoldersReducer.State, RootFoldersReducer.Action> {
    CombineReducers {
      Scope(state: \.systemFoldersSection, action: \.systemFoldersSection) {
        GridSectionReducer()
      }
      Scope(state: \.userFoldersSection, action: \.userFoldersSection) {
        GridSectionReducer()
      }
      BindingReducer()
      Reduce<RootFoldersReducer.State, RootFoldersReducer.Action> { state, action in
        switch action {
        case .didLoad:
          state.loadStatus = .didLoad
          return .none
          
        case .task:
          guard state.loadStatus == .didNotLoad else { return .none }
          state.loadStatus = .isLoading
          return .run { send in
            // TODO: Might be nicer to make this a stream...
            let folders = await database.retrieveRootFolders()
            await send(.fetchFoldersSuccess(.init(uniqueElements: folders)))
            await send(.didLoad)
          }
          
        case let .fetchFoldersSuccess(folders):
          state.userFolders.append(contentsOf: folders)
          state.userFoldersSection.gridItems = folders.map({ .init($0) })
          return .none
          
        case .selectFoldersButtonTapped:
          state.isEditing = true
          state.systemFoldersSection.isExpanded = false
          state.userFoldersSection.isExpanded = true
          state.scrollViewIndex = 1
          return .none
          
        case .doneButtonTapped:
          state.isEditing = false
          state.systemFoldersSection.isExpanded = true
          state.userFoldersSection.selection = []
          state.scrollViewIndex = 1
          return .none
          
        case .selectAllButtonTapped:
          state.userFoldersSection.selection = .init(
            state.hasSelectedAll ? [] : state.userFoldersSection.gridItems.map(\.id)
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
          let newFolder = Folder(
            id: .init(rawValue: uuid()),
            name: "New Untitled Folder",
            folderType: .user,
            creationDate: date(),
            lastEditDate: date()
          )
          state.userFolders.append(newFolder)
          state.userFoldersSection.gridItems.append(.init(newFolder))
          return .send(.delegate(.addNewFolderDidComplete(newFolder.id)), animation: .default)
          
        case .newRecipeButtonTapped:
          let newRecipe = Recipe(
            id: .init(rawValue: uuid()),
            name: "New Untitled Recipe",
            creationDate: date(),
            lastEditDate: date()
          )
          state.systemFolders[id: state.systemStandardFolderID]!.recipes.append(newRecipe)
          return .send(.delegate(.addNewRecipeDidComplete(newRecipe.id)), animation: .default)
          
        case let .userFoldersSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.userFolderTapped(id)))
          }
          
        case let .systemFoldersSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.systemFolderTapped(id)))
          }
        case .binding:
          return .none
          
        case let .alert(.presented(action)):
          switch action {
          case .cancelButtonTapped:
            return .none
            
          case .confirmDeleteButtonTapped:
            state.userFoldersSection.gridItems = state.userFoldersSection.gridItems.filter {
              !state.userFoldersSection.selection.contains($0.id)
            }
            state.userFoldersSection.selection = []
            // TODO: update folders
            return .none
          }
          
        case .alert(.dismiss):
          state.alert = nil
          return .none
          
        case .alert, .systemFoldersSection, .userFoldersSection, .delegate:
          return .none
        }
      }
    }
    .onChange(
      of: \.userFolders,
      removeDuplicates: { ($0.isEmpty && !$1.isEmpty) || $0 == $1 }
    ) { oldFolders, newFolders in
      Reduce { _, _ in
          .run { _ in
            enum UserFoldersUpdateID: Hashable { case debounce }
            try await withTaskCancellation(id: UserFoldersUpdateID.debounce, cancelInFlight: true) {
              // TODO: - Handle DB errors in future
              try await self.clock.sleep(for: .seconds(1))
              for updatedFolder in newFolders.intersectionByID(oldFolders).filter({ newFolders[id: $0.id] != oldFolders[id: $0.id] }) {
                try! await self.database.updateFolder(updatedFolder)
                print("Updated folder \(updatedFolder.id.uuidString)")
              }
              for addedFolder in newFolders.symmetricDifferenceByID(oldFolders) {
                try! await self.database.createFolder(addedFolder)
                print("Created folder \(addedFolder.id.uuidString)")
              }
              for removedFolder in oldFolders.symmetricDifferenceByID(newFolders) {
                try! await self.database.deleteFolder(removedFolder.id)
                print("Deleted folder \(removedFolder.id.uuidString)")
              }
            }
          }
      }
    }
  }
}

extension AlertState where Action == RootFoldersReducer.Action.AlertAction {
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

private extension GridItemReducer.State where ID == Folder.ID {
  init(_ folder: Folder) {
    let actions: Set<GridItemReducer.ContextMenuActions> = {
      if folder.folderType.isSystem {
        .init(arrayLiteral: .editPhotos)
      }
      else {
        .init(GridItemReducer.ContextMenuActions.allCases)
      }
    }()
    self.init(
      id: folder.id,
      name: folder.name,
      imageData: folder.imageData,
      enabledContextMenuActions: actions
    )
  }
}
