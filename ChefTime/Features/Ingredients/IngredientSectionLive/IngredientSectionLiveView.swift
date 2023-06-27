import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: ContextMenu acts weird
// TODO: Scale causes ugly refresh
// TODO: Multiplier will format a sttring, but maybe we shold put a check in place
// if it is empty, keep the string...

// MARK: - View
struct IngredientSectionLiveView: View {
  let store: StoreOf<IngredientSectionLiveReducer>
  
  // TODO: Expand button area not working properly, border hack
  // TODO: Context Menu not working properly, area is messed up
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        if viewStore.isEditing {
          List(selection: viewStore.binding(
            get: \.selection,
            send: { .newSelection($0) }
          )) {
              ForEachStore(store.scope(
              state: \.ingredients,
              action: IngredientSectionLiveReducer.Action.ingredient
              )) { childStore in
                IngredientLiveView(store: childStore)
                  .disabled(true)
                  .tag(ViewStore(childStore).id)
              }
              .onMove { _, _ in
                // ...
              }
            
          }
          .alert(store: store.scope(
            state: \.$alert,
            action: IngredientSectionLiveReducer.Action.alert
          )) // TODO: BUG - Alert not being cleared unless put here.
        }
        else {
          List {
            ForEachStore(store.scope(
              state: \.ingredients,
              action: IngredientSectionLiveReducer.Action.ingredient
            )) { childStore in
              IngredientLiveView(store: childStore)
            }
            .onMove { _, _ in
              
            }
          }
        }
      }
      .listStyle(.plain)
      .environment(\.editMode, .constant(viewStore.isEditing ? .active : .inactive))
      .animation(.default, value: viewStore.isEditing)
      .navigationTitle(viewStore.binding(
        get: \.navigationTitle,
        send: { .ingredientSectionLiveNameEdited($0) }
      ))
      .toolbar {
        if viewStore.isEditing {
          ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
              viewStore.send(.selectAllButtonTapped)
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
                viewStore.send(.addIngredientButtonTapped, animation: .default)
              } label: {
                Label("Add", systemImage: "plus")
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

// TODO: context menu f'd up...
// selection should just highlight whole view not a row
// vertical textfield looks like shit

// MARK: - Reducer
struct IngredientSectionLiveReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientLiveReducer.State>
    var selection: Set<IngredientLiveReducer.State.ID> = []
    var isEditing: Bool = false
    @PresentationState var alert: AlertState<AlertAction>?
    
    var hasSelectedAll: Bool {
      selection.count == ingredients.count
    }
    
    var navigationTitle: String {
      isEditing && selection.count > 0 ? "\(selection.count) Selected": name
    }
    
    
    init(id: ID, ingredientSectionLive: Recipe.IngredientSection) {
      self.id = id
      self.name = ingredientSectionLive.name
      self.ingredients = .init(uniqueElements: ingredientSectionLive.ingredients.map({
        .init(
          id: .init(),
          ingredient: $0
        )
      }))
    }
  }
  
  enum Action: Equatable {
    case ingredient(IngredientLiveReducer.State.ID, IngredientLiveReducer.Action)
    case ingredientSectionLiveNameEdited(String)
    case newSelection(Set<IngredientLiveReducer.State.ID>)
    case selectButtonTapped
    case selectAllButtonTapped
    case doneButtonTapped
    case addIngredientButtonTapped
    case deleteSelectedButtonTapped
    case alert(PresentationAction<AlertAction>)

  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(delegateAction):
          switch delegateAction {
          case .swipedToDelete:
            state.ingredients.remove(id: id)
            return .none
          }
        default:
          return .none
        }
        
      case let .ingredientSectionLiveNameEdited(newName):
        state.name = newName
        return .none
        
      case let .newSelection(newSelection):
        state.selection = newSelection
        return .none
        
      case .selectButtonTapped:
        state.isEditing = true
        return .none
        
      case .selectAllButtonTapped:
        state.selection = state.hasSelectedAll ? [] : .init(state.ingredients.map(\.id))
        return .none
        
      case .doneButtonTapped:
        state.isEditing = false
        state.selection = []
        return .none
        
      case .addIngredientButtonTapped:
        var s = IngredientLiveReducer.State.init(
          id: .init(),
          ingredient: .init(
            id: .init(),
            name: "",
            amount: 0,
            measure: ""
          )
        )
        s.ingredientAmountString = ""
        state.ingredients.append(s)
        return .none
      
      case .deleteSelectedButtonTapped:
        state.alert = .init(
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
        )
        return .none
        
      case let .alert(action):
        switch action {
        case .presented(.confirmDeleteSelected):
          state.ingredients = state.ingredients.filter {
            !state.selection.contains($0.id)
          }
          state.selection = []
          state.isEditing = false
          return .none
        
        case .dismiss:
          return .none
        }
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientLiveReducer()
    }
  }
}

extension IngredientSectionLiveReducer {
  enum AlertAction: Equatable {
    case confirmDeleteSelected
  }
  
  enum DelegateAction: Equatable {
    case deleteSectionLiveButtonTapped
    case sectionNavigationAreaTapped
  }
}

// MARK: - Previews
struct IngredientSectionLiveView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      IngredientSectionLiveView(store: .init(
        initialState: .init(
          id: .init(),
          ingredientSectionLive: Recipe.longMock.ingredientSections.first!
        ),
        reducer: IngredientSectionLiveReducer.init
      ))
    }
  }
}
