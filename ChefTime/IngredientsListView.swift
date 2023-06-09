import SwiftUI
import ComposableArchitecture

// MARK: - IngredientsListView
struct IngredientsListView: View {
  let store: StoreOf<IngredientsListReducer>
  @State var string: String = ""
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        Stepper {
          Text("Servings \(viewStore.scale)")
            .font(.title3)
            .fontWeight(.bold)
        } onIncrement: {
          viewStore.send(.scaleStepperIncrementButtonTapped)
        } onDecrement: {
          viewStore.send(.scaleStepperDecrementButtonTapped)
        }
        ForEachStore(store.scope(
          state: \.viewState.ingredients,
          action: IngredientsListReducer.Action.ingredient
        )) { childStore in
          IngredientSectionView(store: childStore)
        }
      }
      label : {
        Text("Ingredients")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .accentColor(.primary)
    }
  }
}

// MARK: - IngredientsListReducer
struct IngredientsListReducer: ReducerProtocol {
  struct State: Equatable {
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
    case isExpandedButtonToggled
    case scaleStepperIncrementButtonTapped
    case scaleStepperDecrementButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(delegateAction):
          switch delegateAction {
          case .deleteSectionButtonTapped:
            state.viewState.ingredients.remove(id: id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.viewState.isExpanded.toggle()
        return .none
        
      case .scaleStepperIncrementButtonTapped:
        let oldScale = state.viewState.scale
        let newScale: Double = {
          if oldScale == (1/4) {
            return 1/2
          }
          else if oldScale == (1/2) {
            return 1
          }
          else if oldScale > 100 {
            return oldScale
          }
          else {
            return Double(oldScale + 1)
          }
        }()
        state.viewState.scale = newScale
        
        state.viewState.ingredients.indices.forEach { i in
          state.viewState.ingredients[i].viewState.ingredients.indices.forEach { j in
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount /= oldScale
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount *= newScale
          }
        }
        return .none
        
      case .scaleStepperDecrementButtonTapped:
        let oldScale = state.viewState.scale
        let newScale: Double = {
          if oldScale == (1/4) {
            return 1/4
          }
          else if oldScale == (1/2) {
            return 1/4
          }
          else {
            return oldScale - 1
          }
        }()
        state.viewState.scale = newScale
        state.viewState.ingredients.indices.forEach { i in
          state.viewState.ingredients[i].viewState.ingredients.indices.forEach { j in
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount /= oldScale
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount *= newScale
          }
        }
        return .none
      }
    }
    .forEach(\.viewState.ingredients, action: /Action.ingredient) {
      IngredientSectionReducer()
    }
    .debug()
  }
}

extension IngredientsListReducer {
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    init(recipe: Recipe) {
      self.ingredients = .init(uniqueElements: recipe.ingredients.map({
        .init(
          id: .init(),
          viewState: .init(
            ingredientSection: .init(
              id: .init(),
              name: $0.name,
              ingredients: $0.ingredients
            ),
            isExpanded: true
          )
        )
      }))
      self.scale = 1.0
      self.isExpanded = true
    }
  }
}

// MARK: - Previews
struct IngredientsListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientsListView(store: .init(
          initialState: .init(
            viewState: .init(
              recipe: Recipe.mock
            )
          ),
          reducer: IngredientsListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .padding()
    }
  }
}
