import ComposableArchitecture

@Reducer
struct GridSectionReducer<ID: Equatable & Hashable> {
  struct State: Equatable {
    let title: String
    var gridItems: IdentifiedArrayOf<GridItemReducer<ID>.State> = []
    @BindingState var isExpanded: Bool = true
    @BindingState var selection = Set<GridItemReducer<ID>.State.ID>()
    
    init(title: String = "Recipes", gridItems: IdentifiedArrayOf<GridItemReducer<ID>.State>) {
      self.title = title
      self.gridItems = gridItems
      self.isExpanded = true
      self.selection = []
    }
  }
  
  enum Action: Equatable, BindableAction {
    case gridItemSelected(GridItemReducer<ID>.State.ID)
    case gridItems(IdentifiedActionOf<GridItemReducer<ID>>)
    case binding(BindingAction<State>)
    
    case delegate(DelegateAction)
    @CasePathable
    @dynamicMemberLookup
    enum DelegateAction: Equatable {
      case gridItemTapped(GridItemReducer<ID>.State.ID)
    }
  }
  
  var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .gridItemSelected(id):
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        
        return .none
        
      case let .gridItems(.element(id: id, action: .delegate(action))):
        switch action {
        case .move:
          break
        case .delete:
          state.gridItems.remove(id: id)
          break
        }
        return .none
        
        
      case .gridItems, .binding, .delegate:
        return .none
      }
    }
    .forEach(\.gridItems, action: \.gridItems, element: GridItemReducer.init)
    .signpost()
  }
}
