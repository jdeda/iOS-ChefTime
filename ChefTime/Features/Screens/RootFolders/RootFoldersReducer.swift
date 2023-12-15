import ComposableArchitecture
import Log4swift

// TODO: Rename FoldersReduer to RootFoldersReducer
// TODO: Deal with seperation of systemFolders, specificSystemFolders, and userFolders.
struct RootFoldersReducer: Reducer {
  struct State: Equatable {
    var loadStatus = LoadStatus.didNotLoad
    var userFolders: IdentifiedArrayOf<Folder>
    var userFoldersSection: GridSectionReducer<Folder.ID>.State
    var search: SearchReducer.State
    var isHidingImages: Bool
    @BindingState var isEditing: Bool
    @PresentationState var destination: DestinationReducer.State?
    
    init(userFolders: IdentifiedArrayOf<Folder> = []) {
      self.userFolders = userFolders
      self.userFoldersSection = .init(title: "Folders", gridItems: userFolders.map(GridItemReducer.State.init))
      self.search = .init(query: "")
      self.isHidingImages = false
      self.isEditing = false
      self.destination = nil
    }
    
    var hasSelectedAll: Bool {
      userFoldersSection.selection.count == userFoldersSection.gridItems.count
    }
    
    var navigationTitle: String {
      let value = isEditing && userFoldersSection.selection.count > 0
      return value ? "\(userFoldersSection.selection.count) Selected": "Home"
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
    case deleteSelectedButtonTapped
    case newFolderButtonTapped
    case acceptFolderNameButtonTapped(String)
    case userFoldersSection(GridSectionReducer<Folder.ID>.Action)
    case search(SearchReducer.Action)
    case binding(BindingAction<State>)
    
    case delegate(DelegateAction)
    enum DelegateAction: Equatable {
      case navigateToFolder(Folder.ID)
      case navigateToRecipe(Recipe.ID)
    }
    
    case destination(PresentationAction<DestinationReducer.Action>)
  }
  
  @Dependency(\.database) var database
  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid
  @Dependency(\.date) var date
  
  var body: some Reducer<RootFoldersReducer.State, RootFoldersReducer.Action> {
    CombineReducers {
      Scope(state: \.userFoldersSection, action: /RootFoldersReducer.Action.userFoldersSection) {
        GridSectionReducer()
      }
      Scope(state: \.search, action: /RootFoldersReducer.Action.search) {
        SearchReducer()
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
          state.userFolders = .init(uniqueElements: folders)
          state.userFoldersSection.gridItems = folders.map({ .init($0) })
          return .none
          
        case .selectFoldersButtonTapped:
          state.isEditing = true
          state.userFoldersSection.isExpanded = true
          return .none
          
        case .doneButtonTapped:
          state.isEditing = false
          state.userFoldersSection.selection = []
          for id in state.userFoldersSection.gridItems.ids {
            state.userFoldersSection.gridItems[id: id]?.isSelected = false
          }
          return .none
          
        case .selectAllButtonTapped:
          state.userFoldersSection.selection = .init(
            state.hasSelectedAll ? [] : state.userFoldersSection.gridItems.map(\.id)
          )
          state.userFoldersSection.gridItems.ids.forEach { id in
            state.userFoldersSection.gridItems[id: id]!.isSelected = state.hasSelectedAll
          }
          return .none
          
        case .hideImagesButtonTapped:
          state.isHidingImages.toggle()
          return .none
          
        case .deleteSelectedButtonTapped:
          state.destination = .alert(.delete)
          return .none
          
        case .newFolderButtonTapped:
          state.destination = .nameNewFolderAlert
          return .none
          
        case let .acceptFolderNameButtonTapped(name):
          state.destination = nil
          let newFolder = Folder(
            id: .init(rawValue: uuid()),
            name: name,
            folderType: .user,
            creationDate: date(),
            lastEditDate: date()
          )
          state.userFolders.append(newFolder)
          state.userFoldersSection.gridItems.append(.init(newFolder))
          return .run { send in
            try! await self.database.createFolder(newFolder)
            // We sleep briefly here to see the folder get inserted into the UI
            try await clock.sleep(for: .milliseconds(500))
            await send(.delegate(.navigateToFolder(newFolder.id)), animation: .default)
          }
          
          
        case let .userFoldersSection(.delegate(action)):
          switch action {
          case let .gridItemTapped(id):
            return .send(.delegate(.navigateToFolder(id)))
          }
          
        case .userFoldersSection:
          let oldFolders = state.userFolders
          let newIDs = state.userFoldersSection.gridItems.ids
          state.userFolders = state.userFolders.reduce(into: []) { partial, folder in
            if newIDs.contains(folder.id) {
              var mutatedFolder = folder
              mutatedFolder.name = state.userFoldersSection.gridItems[id: folder.id]!.name
              mutatedFolder.imageData = state.userFoldersSection.gridItems[id: folder.id]!.photos.photos.first
              partial.append(mutatedFolder)
            }
          }
          return self.persistFolders(oldFolders: oldFolders, newFolders: state.userFolders)
          
        case let .search(.delegate(.searchResultTapped(id))):
          return .send(.delegate(.navigateToRecipe(id)))
          
        case .binding:
          return .none
          
        case let .destination(.presented(.alert(action))):
          switch action {
          case .cancelButtonTapped:
            return .none
            
          case .confirmDeleteButtonTapped:
            let deletionIDs = state.userFoldersSection.selection
            state.userFoldersSection.gridItems = state.userFoldersSection.gridItems.filter {
              !deletionIDs.contains($0.id)
            }
            state.userFoldersSection.selection = []
            return .run { send in
              for id in deletionIDs {
                try! await self.database.deleteFolder(id)
              }
            }
          }
          
          // TODO: Make sure dismissal works
        case .destination(.dismiss):
          state.destination = nil
          return .none
          
//        case .alert(.dismiss):
//          state.alert = nil
//          return .none
          
        case .destination, .delegate, .search:
          return .none
        }
      }
      .ifLet(\.$destination, action: /RootFoldersReducer.Action.destination) {
        DestinationReducer()
      }
    }
    .signpost()
  }
}

extension RootFoldersReducer {
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
}

extension RootFoldersReducer {
  struct DestinationReducer: Reducer {
    enum State: Equatable {
      case alert(AlertState<Action.AlertAction>)
      case nameNewFolderAlert
    }
    
    enum Action: Equatable {
      case nameNewFolderAlert
      case alert(AlertAction)
      enum AlertAction: Equatable {
        case cancelButtonTapped // TODO: Rename this
        case confirmDeleteButtonTapped
      }
    }
    
    var body: some ReducerOf<Self> {
      EmptyReducer()
    }
  }
}

extension AlertState where Action == RootFoldersReducer.DestinationReducer.Action.AlertAction {
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
      description: "\(folder.recipes.count) Recipes",
      imageData: folder.imageData,
      enabledContextMenuActions: actions
    )
  }
}
