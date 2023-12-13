import ComposableArchitecture

struct GridSectionReducer<ID: Equatable & Hashable>: Reducer {
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
//    case gridItemSelected(GridItemReducer<ID>.State.ID)
    case gridItems(GridItemReducer<ID>.State.ID, GridItemReducer<ID>.Action)
    case binding(BindingAction<State>)
    
    case delegate(DelegateAction)
    
    
    enum DelegateAction: Equatable {
      case gridItemTapped(GridItemReducer<ID>.State.ID)
    }
  }
  
  var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
//        
//      case let .gridItemSelected(id):
//        // TODO: Check force unwraps?
//        if state.selection.contains(id) {
//          state.selection.remove(id)
//          state.gridItems[id: id]!.isSelected = false
//        }
//        else {
//          state.selection.insert(id)
//          state.gridItems[id: id]!.isSelected = true
//        }
//        
//        return .none
        
      case let .gridItems(id, .delegate(action)):
        switch action {
        case .gridItemTapped:
          return .send(.delegate(.gridItemTapped(id)), animation: .default)
          
        case .gridItemSelected:
          if state.selection.contains(id) {
            state.selection.remove(id)
            state.gridItems[id: id]!.isSelected = false
          }
          else {
            state.selection.insert(id)
            state.gridItems[id: id]!.isSelected = true
          }
          return .none
          
        case .delete:
          state.gridItems.remove(id: id)
          break
        }
        return .none
        
        
      case .gridItems, .binding, .delegate:
        return .none
      }
    }
    .forEach(\.gridItems, action: /GridSectionReducer.Action.gridItems) {
      GridItemReducer()
    }
    .signpost()
  }
}
