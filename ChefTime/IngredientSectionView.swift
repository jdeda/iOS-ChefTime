import SwiftUI
import ComposableArchitecture

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
          VStack {
            IngredientView(store: childStore)
            Divider()
          }
        }
      } label: {
        Text(viewStore.ingredientSection.name)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .accentColor(.primary)
    }
  }
}

struct IngredientSectionReducer: ReducerProtocol  {
  struct State: Equatable {
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        return .none
        
      case .isExpandedButtonToggled:
        state.viewState.isExpanded.toggle()
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
    var ingredientSection: Recipe.Ingredients
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    
    init(ingredientSection: Recipe.Ingredients, isExpanded: Bool) {
      self.ingredientSection = ingredientSection
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

struct IngredientSectionView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientSectionView(store: .init(
          initialState: .init(
            viewState: .init(
              ingredientSection: Recipe.mock.ingredients.first!,
              isExpanded: true
            )
          ),
          reducer: IngredientSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .padding()
    }
  }
}
