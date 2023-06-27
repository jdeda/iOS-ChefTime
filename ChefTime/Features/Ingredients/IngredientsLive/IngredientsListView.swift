import SwiftUI
import ComposableArchitecture

// TODO: Section deletion has no animation

// MARK: - IngredientsListView
struct IngredientListView: View {
  let store: StoreOf<IngredientsListReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 } ) { viewStore in
      VStack {
        if !viewStore.isEditing {
          List {
            IngredientStepper(scale: viewStore.binding(
              get: \.scale,
              send: { .scaleStepperButtonTapped($0) }
            ))
            ForEachStore(store.scope(
              state: \.ingredients,
              action: IngredientsListReducer.Action.ingredient
            )) { childStore in
              IngredientSectionView(store: childStore)
            }
          }
        }
        else {
          List(selection: viewStore.binding(
            get: \.selection,
            send: { .newSelection($0) }
          )) {
            ForEachStore(store.scope(
              state: \.ingredients,
              action: IngredientsListReducer.Action.ingredient
            )) { childStore in
              WithViewStore(childStore) { childViewStore in
                HStack {
                  TextField(
                    "Untitled Ingredient Section",
                    text: .constant(childViewStore.name),
                    axis: .vertical
                  )
                  .font(.title3)
                  .fontWeight(.bold)
                  .foregroundColor(.primary)
                  .accentColor(.accentColor)
                  .frame(alignment: .leading)
                  .multilineTextAlignment(.leading)
                  Spacer()
                }
                .tag(childViewStore.id)
              }
            }
            .onMove { indexSet, index in
              viewStore.send(.onMove(indexSet, index), animation: .default)
            }
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle(viewStore.navigationTitle)
      .environment(\.editMode, .constant(viewStore.isEditing ? .active : .inactive))
      .animation(.default, value: viewStore.isEditing)
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
        state: /IngredientsListReducer.DestinationReducer.State.alert,
        action: IngredientsListReducer.DestinationReducer.Action.alert
      )
      .navigationDestination(
        store: store.scope(state: \.$destination, action: IngredientsListReducer.Action.destination),
        state: /IngredientsListReducer.DestinationReducer.State.section,
        action: IngredientsListReducer.DestinationReducer.Action.section,
        destination: IngredientSectionLiveView.init
      )
      .toolbar {
        if viewStore.isEditing {
          ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
              viewStore.send(.selectAllButtonTapped, animation: .default)
            } label: {
              Text(viewStore.hasSelectedAll ? "Deselect All" : "Select All")
            }
          }
          ToolbarItemGroup(placement: .primaryAction) {
            Button {
              viewStore.send(.doneButtonTapped, animation: .default)
            } label: {
              Text("Done")
            }
          }
          ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            Button {
              viewStore.send(.deleteSelectedButtonTapped, animation: .default)
            } label: {
              Image(systemName: "trash")
            }
            .disabled(viewStore.selection.count == 0)
          }
        }
        else {
          ToolbarItemGroup(placement: .primaryAction) {
            Menu {
              Button {
                viewStore.send(.selectButtonTapped, animation: .default)
              } label: {
                Label("Edit", systemImage: "checkmark")
              }
              Button {
                viewStore.send(.addSectionButtonTapped, animation: .default)
              } label: {
                Label("Add", systemImage: "plus")
              }
              Button {
                viewStore.send(.expandAllButtonTapped, animation: .default)
              } label: {
                Label("Expand All", systemImage: "arrow.up.left.and.arrow.down.right")
              }
              Button {
                viewStore.send(.collapseAllButtonTapped, animation: .default)
              } label: {
                Label("Collapse All", systemImage: "arrow.down.right.and.arrow.up.left")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
            .foregroundColor(.primary)
          }
        }
      }
    }
  }
}

// MARK: - IngredientsListReducer
struct IngredientsListReducer: ReducerProtocol {
  struct State: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    var selection: Set<IngredientSectionReducer.State.ID> = []
    var isEditing: Bool = false
    @PresentationState var destination: DestinationReducer.State?
    
    var hasSelectedAll: Bool {
      selection.count == ingredients.count
    }
    
    var navigationTitle: String {
      isEditing && selection.count > 0 ? "\(selection.count) Selected": "Ingredients"
    }
    
    init(
      recipe: Recipe,
      isExpanded: Bool,
      childrenIsExpanded: Bool,
      destination: DestinationReducer.State? = nil
    ) {
      self.ingredients = .init(uniqueElements: recipe.ingredientSections.map({
        .init(
          id: .init(),
          ingredientSection: .init(
            id: .init(),
            name: $0.name,
            ingredients: $0.ingredients
          ),
          isExpanded: childrenIsExpanded
        )
      }))
      self.scale = 1.0
      self.isExpanded = isExpanded
      self.destination = destination
    }
  }
  
  enum Action: Equatable {
    case scaleStepperButtonTapped(Double)
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
    case isExpandedButtonToggled
    case newSelection(Set<IngredientSectionReducer.State.ID>)
    case selectButtonTapped
    case collapseAllButtonTapped
    case expandAllButtonTapped
    case collapseAll
    case setIsEditing(Bool)
    case selectAllButtonTapped
    case doneButtonTapped
    case addSectionButtonTapped
    case deleteSelectedButtonTapped
    case onMove(IndexSet, Int)
    case destination(PresentationAction<DestinationReducer.Action>)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .scaleStepperButtonTapped(newScale):
        let oldScale = state.scale
        state.scale = newScale
        for i in state.ingredients.indices {
          for j in state.ingredients[i].ingredients.indices {
            let vs = state.ingredients[i].ingredients[j]
            guard !vs.ingredientAmountString.isEmpty else { continue }
            let a = (vs.ingredient.amount / oldScale) * newScale
            let s = String(a)
            state.ingredients[i].ingredients[j].ingredient.amount = a
            state.ingredients[i].ingredients[j].ingredientAmountString = s
          }
        }
        return .none
        
      case let .ingredient(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .deleteSectionButtonTapped:
            state.ingredients.remove(id: id)
            return .none
            
          case .sectionNavigationAreaTapped:
            let s = state.ingredients[id: id]!
            state.destination = .section(.init(
              id: .init(),
              ingredientSectionLive: .init(
                id: .init(),
                name: s.name,
                ingredients: .init(uniqueElements: s.ingredients.map(\.ingredient))
              )
            ))
            return .none
          }
        default:
          return .none
        }
        return .none
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .newSelection(newSelection):
        state.selection = newSelection
        return .none
        
      case .selectButtonTapped:
        return .run { send in
          await send(.collapseAll, animation: .default)
          try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
          await send(.setIsEditing(true), animation: .default)
        }
        
      case .collapseAll:
        state.ingredients.ids.forEach {
          state.ingredients[id: $0]?.isExpanded = false
        }
        return .none
        
      case let .setIsEditing(value):
        state.isEditing = value
        return .none
        
      case .selectAllButtonTapped:
        state.selection = state.hasSelectedAll ? [] : .init(state.ingredients.map(\.id))
        state.isExpanded = true
        return .none
        
      case .doneButtonTapped:
        state.isEditing = false
        state.ingredients.ids.forEach {
          state.ingredients[id: $0]?.isExpanded = true
        }
        return .none
        
      case .addSectionButtonTapped:
        state.ingredients.append(.init(
          id: .init(),
          ingredientSection: .init(
            id: .init(),
            name: "",
            ingredients: []
          ),
          isExpanded: true
        ))
        return .none
        
      case .collapseAllButtonTapped:
        state.ingredients.ids.forEach {
          state.ingredients[id: $0]?.isExpanded = false
        }
        return .none
        
      case .expandAllButtonTapped:
        state.ingredients.ids.forEach {
          state.ingredients[id: $0]?.isExpanded = true
        }
        return .none
        
      case .deleteSelectedButtonTapped:
        state.destination = .alert(.init(
          title: { TextState("Delete Selected") },
          actions: {
            ButtonState(
              role: .destructive,
              action: .send(.confirmDeleteSelected, animation: .default)
            ) {
              TextState("Confirm")
            }
          },
          message: {
            TextState("Are you sure you want to delete the selected items?")
          }
        ))
        return .none
        
      case let .onMove(source, destination):
        state.ingredients.move(fromOffsets: source, toOffset: destination)
        return .none
        
      case let .destination(action):
        switch action {
        case let .presented(.alert(action)):
          switch action {
          case .confirmDeleteSelected:
            state.ingredients = state.ingredients.filter {
              !state.selection.contains($0.id)
            }
            state.selection = []
            state.isEditing = false
            state.ingredients.ids.forEach {
              state.ingredients[id: $0]?.isExpanded = true
            }
            return .none
          }
        case .presented(.section):
          return .none
          
        case .dismiss:
          return .none
        }
        return .none
        
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientSectionReducer()
    }
    .ifLet(\.$destination, action: /Action.destination, destination: {
      DestinationReducer()
    })
    ._printChanges()
  }
}

extension IngredientsListReducer {
  struct DestinationReducer: ReducerProtocol {
    enum State: Equatable {
      case section(IngredientSectionLiveReducer.State)
      case alert(AlertState<AlertAction>)
    }
    
    enum Action: Equatable {
      case section(IngredientSectionLiveReducer.Action)
      case alert(AlertAction)
    }
    
    var body: some ReducerProtocolOf<Self> {
      Scope(state: /State.section, action: /Action.section) {
        IngredientSectionLiveReducer()
      }
      EmptyReducer()
    }
  }
  
  enum AlertAction {
    case confirmDeleteSelected
  }
}

// MARK: - Previews
struct IngredientList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      IngredientListView(store: .init(
        initialState: .init(
          recipe: Recipe.shortMock,
          isExpanded: true,
          childrenIsExpanded: true
        ),
        reducer: IngredientsListReducer.init
      ))
    }
  }
}
