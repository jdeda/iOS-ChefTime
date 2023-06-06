import SwiftUI
import ComposableArchitecture

// MARK: - View
struct IngredientSectionView: View {
  let store: StoreOf<IngredientSectionReducer>
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.viewState.ingredients,
          action: IngredientSectionReducer.Action.ingredient
        )) { childStore in
          IngredientView(store: childStore)
        }
      } label: {
        TextField("Untitled Ingredient Section", text: viewStore.binding(
          get: { $0.name},
          send: { .ingredientSectionNameEdited($0) }
        ))
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
      }
      .accentColor(.primary)
    }
  }
}

// MARK: - Reducer
struct IngredientSectionReducer: ReducerProtocol  {
  struct State: Equatable {
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(delegateAction):
          switch delegateAction {
          case .swipedToDelete:
            state.viewState.ingredients.remove(id: id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.viewState.isExpanded.toggle()
        return .none
        
      case let .ingredientSectionNameEdited(newName):
        state.viewState.name = newName
        return .none
      }
    }
    .forEach(\.viewState.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
  }
}

extension IngredientSectionReducer {
  struct ViewState: Equatable {
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    
    init(ingredientSection: Recipe.Ingredients, isExpanded: Bool) {
      self.name = ingredientSection.name
      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
        .init(
          id: .init(),
          viewState: .init(
            ingredient: $0
          )
        )
      }))
      self.isExpanded = isExpanded
    }
  }
}

// MARK: - Previews
struct IngredientSectionView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      List {
        IngredientSectionView(store: .init(
          initialState: .init(
            viewState: .init(
              ingredientSection: Recipe.mock.ingredients[1],
              isExpanded: true
            )
          ),
          reducer: IngredientSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .listStyle(.plain)
      .padding()
    }
  }
}
