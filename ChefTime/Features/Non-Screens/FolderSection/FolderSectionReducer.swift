import ComposableArchitecture

// MARK: - Reducer
struct FolderSectionReducer: Reducer {
  struct State: Equatable {
    let title: String
    var folders: IdentifiedArrayOf<FolderGridItemReducer.State> = []
    @BindingState var isExpanded: Bool = true
    @BindingState var selection = Set<FolderGridItemReducer.State.ID>()
    
    init(title: String = "Folders", folders: IdentifiedArrayOf<Folder>) {
      self.title = title
      self.folders = folders.map({ .init(folder: $0) })
      self.isExpanded = true
      self.selection = []
    }
  }
  
  enum Action: Equatable, BindableAction {
    case folderSelected(FolderGridItemReducer.State.ID)
    case folders(FolderGridItemReducer.State.ID, FolderGridItemReducer.Action)
    case binding(BindingAction<State>)
    
    case folderTapped(FolderGridItemReducer.State.ID)
    
    case delegate(DelegateAction)
    enum DelegateAction: Equatable {
      case folderTapped(FolderGridItemReducer.State.ID)
    }
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .folderSelected(id):
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        
        return .none
        
      case let .folders(id, .delegate(action)):
        switch action {
        case .move:
          break
        case .delete:
          state.folders.remove(id: id)
          break
        }
        return .none
        
        
      case let .folderTapped(id):
        return .send(.delegate(.folderTapped(id)))
        
      case .folders, .binding, .delegate:
        return .none
      }
    }
    .forEach(\.folders, action: /Action.folders) {
      FolderGridItemReducer()
    }
    
  }
}

// MARK: - DelegateAction
extension FolderSectionReducer {
//  enum DelegateAction: Equatable {
//    case folderTapped(FolderGridItemReducer.State.ID)
//  }
}
