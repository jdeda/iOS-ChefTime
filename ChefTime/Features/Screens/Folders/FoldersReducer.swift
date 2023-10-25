import ComposableArchitecture
import SwiftUI
import Tagged

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
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
  }
  
  enum Action: Equatable, BindableAction {
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
  }
  
  @Dependency(\.database) var database
  @Dependency(\.continuousClock) var clock
  @Dependency(\.uuid) var uuid
  
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
        case .task:
          return .run { send in
            // TODO: Might be nicer to make this a stream...
            let folders = await database.retrieveRootFolders()
            await send(.fetchFoldersSuccess(.init(uniqueElements: folders)))
            return
          }
          
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
          let newFolder = FolderGridItemReducer.State(folder: .init(
            id: .init(rawValue: uuid()),
            name: "New Untitled Folder",
            folderType: .user
          ))
          state.userFoldersSection.folders.append(newFolder)
          return .send(.delegate(.addNewFolderButtonTappedDidComplete(newFolder.id)), animation: .default)
          
        case .newRecipeButtonTapped:
          let newRecipe = Recipe(id: .init(rawValue: uuid()), name: "New Untitled Recipe")
          state.systemFoldersSection.folders[1].folder.recipes.append(newRecipe)
          return .send(.delegate(.addNewRecipeButtonTappedDidComplete(newRecipe.id)), animation: .default)
          
        case let .userFoldersSection(.delegate(action)):
          switch action {
          case let .folderTapped(id):
            guard let _ = state.userFoldersSection.folders[id: id]?.folder
            else { return .none }
            return .none
          }
          
        case let .systemFoldersSection(.delegate(action)):
          switch action {
          case let .folderTapped(id):
            guard let _ = state.systemFoldersSection.folders[id: id]?.folder
            else { return .none }
            return .none
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
    .onChange(of: { $0.userFoldersSection.folders.map(\.folder) }) { oldFolders, newFolders in
      Reduce { _, _ in
          .run { _ in
            enum UserFoldersUpdateID: Hashable { case debounce }
            try await withTaskCancellation(id: UserFoldersUpdateID.debounce, cancelInFlight: true) {
              try await self.clock.sleep(for: .seconds(1))
              for updatedFolder in newFolders.intersectionByID(oldFolders).filter({ newFolders[id: $0.id] != oldFolders[id: $0.id] }) {
                await self.database.updateFolder(updatedFolder)
                print("Updated folder \(updatedFolder.id.uuidString)")
              }
              for addedFolder in newFolders.symmetricDifferenceByID(oldFolders) {
                await self.database.createFolder(addedFolder)
                print("Created folder \(addedFolder.id.uuidString)")
              }
              for removedFolders in oldFolders.symmetricDifferenceByID(newFolders) {
                await self.database.deleteFolder(removedFolders)
                print("Deleted folder \(removedFolders.id.uuidString)")
              }
            }
          }
      }
    }
    .onChange(of: \.systemFoldersSection.folders) { _, _ in
      EmptyReducer() // TODO: ....
    }
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
  enum DelegateAction: Equatable {
    case addNewFolderButtonTappedDidComplete(FolderGridItemReducer.State.ID)
    case addNewRecipeButtonTappedDidComplete(Recipe.ID)
  }
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
