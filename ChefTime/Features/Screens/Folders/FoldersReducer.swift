import ComposableArchitecture
import SwiftUI
import Tagged


// TODO: Deal with seperation of systemFolders, specificSystemFolders, and userFolders.

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var didLoad = false
    var systemFoldersSection: FolderSectionReducer.State
    var userFoldersSection: FolderSectionReducer.State
    var scrollViewIndex: Int
    var isHidingImages: Bool
    @BindingState var isEditing: Bool
    @PresentationState var alert: AlertState<AlertAction>?
    
    init(
      systemFolders: IdentifiedArrayOf<Folder> = [],
      userFolders: IdentifiedArrayOf<Folder> = []
    ) {
      self.systemFoldersSection = .init(title: "System", folders: systemFolders)
      self.userFoldersSection = .init(title: "User", folders: userFolders)
      self.scrollViewIndex = 1
      self.isHidingImages = false
      self.isEditing = false
      self.alert = nil
    }
    
    var hasSelectedAll: Bool {
      userFoldersSection.selection.count == userFoldersSection.folders.count
    }
    
    var navigationTitle: String {
      let value = isEditing && userFoldersSection.selection.count > 0
      return value ? "\(userFoldersSection.selection.count) Selected": "Folders"
    }
    
    var systemStandardFolderID: Folder.ID {
      self.systemFoldersSection.folders.first(where: { $0.folder.folderType == .systemStandard })!.id
    }
  }
  
  enum Action: Equatable, BindableAction {
    case setDidLoad(Bool)
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
    case userFoldersSection(FolderSectionReducer.Action)
    case systemFoldersSection(FolderSectionReducer.Action)
    case alert(PresentationAction<AlertAction>)
    case binding(BindingAction<State>)
    
    case delegate(DelegateAction)
    enum DelegateAction: Equatable {
      case addNewFolderDidComplete(Folder.ID)
      case addNewRecipeDidComplete(Recipe.ID)
      case userFolderTapped(Folder.ID)
      case systemFolderTapped(Folder.ID)
    }
  }
  
  @Dependency(\.database) var database
  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid
  @Dependency(\.date) var date

  var body: some Reducer<FoldersReducer.State, FoldersReducer.Action> {
    CombineReducers {
      Scope(state: \.systemFoldersSection, action: /Action.systemFoldersSection) {
        FolderSectionReducer()
      }
      Scope(state: \.userFoldersSection, action: /Action.userFoldersSection) {
        FolderSectionReducer()
      }
      BindingReducer()
      Reduce<FoldersReducer.State, FoldersReducer.Action> { state, action in
        switch action {
        case let .setDidLoad(didLoad):
          state.didLoad = didLoad
          return .none
          
        case .task:
          guard !state.didLoad else { return .none }
          return .run { send in
            // TODO: Might be nicer to make this a stream...
            let folders = await database.retrieveRootFolders()
            await send(.fetchFoldersSuccess(.init(uniqueElements: folders)))
          }
          .concatenate(with: .send(.setDidLoad(true)))
          
        case let .fetchFoldersSuccess(folders):
          state.userFoldersSection.folders = folders.map({
            .init(folder: $0)
          })
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
          let newFolder = Folder(
            id: .init(rawValue: uuid()),
            name: "New Untitled Folder",
            folderType: .user,
            creationDate: date(),
            lastEditDate: date()
          )
          state.userFoldersSection.folders.append(.init(folder: newFolder))
          return .send(.delegate(.addNewFolderDidComplete(newFolder.id)), animation: .default)
          
        case .newRecipeButtonTapped:
          let newRecipe = Recipe(
            id: .init(rawValue: uuid()),
            name: "New Untitled Recipe",
            creationDate: date(),
            lastEditDate: date()
          )
          state.systemFoldersSection.folders[id: state.systemStandardFolderID]!.folder.recipes.append(newRecipe)
          return .send(.delegate(.addNewRecipeDidComplete(newRecipe.id)), animation: .default)
          
        case let .userFoldersSection(.delegate(action)):
          switch action {
          case let .folderTapped(id):
            guard let _ = state.userFoldersSection.folders[id: id]?.folder
            else { return .none }
            return .send(.delegate(.userFolderTapped(id)))
          }
          
        case let .systemFoldersSection(.delegate(action)):
          switch action {
          case let .folderTapped(id):
            guard let _ = state.systemFoldersSection.folders[id: id]?.folder
            else { return .none }
            return .send(.delegate(.systemFolderTapped(id)))
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
    }
    .onChange(
      of: { $0.userFoldersSection.folders.map(\.folder) },
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
//    .onChange(of: \.systemFoldersSection.folders) { _, _ in
//      EmptyReducer() // TODO: ....
//    }
  }
}

// MARK: - Action.FolderUpdate
extension FoldersReducer.Action {
  enum FoldersUpdate: Equatable {
    case systemFolders
    case userFolders
  }
}

// MARK: - AlertAction
extension FoldersReducer {
//  enum DelegateAction: Equatable {
//    case addNewFolderDidComplete(Folder.ID)
//    case addNewRecipeDidComplete(Recipe.ID)
//    case userFolderTapped(Folder.ID)
//    case systemFolderTapped(Folder.ID)
//  }
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
        //        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "All", folderType: .systemAll)),
        //        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "Standard", folderType: .systemStandard)),
        //        .init(id: .init(rawValue: uuid()), folder: .init(id: .init(rawValue: uuid()), name: "Recently Deleted", folderType: .systemRecentlyDeleted))
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
