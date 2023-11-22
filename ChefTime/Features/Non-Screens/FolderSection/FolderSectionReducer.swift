import ComposableArchitecture

@Reducer
struct FolderSectionReducer {
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
    case folders(IdentifiedActionOf<FolderGridItemReducer>)
    case binding(BindingAction<State>)
    case folderTapped(FolderGridItemReducer.State.ID)
    
    case delegate(DelegateAction)
    @CasePathable
    @dynamicMemberLookup
    enum DelegateAction: Equatable {
      case folderTapped(FolderGridItemReducer.State.ID)
    }
  }
  
  var body: some Reducer<State, Action> {
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
        
      case let .folders(.element(id: id, action: .delegate(action))):
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
    .forEach(\.folders, action: \.folders, element: FolderGridItemReducer.init)
  }
}
