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
        Stepper(
          value: viewStore.binding(
            get: { $0.scale },
            send: { .scaleStepperButtonTapped($0) }
        ),
          in: 1...100
        ) {
          Text("Servings \(viewStore.scale)")
            .font(.title3)
            .fontWeight(.bold)
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
    case scaleStepperButtonTapped(Int)
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
        
      case let .scaleStepperButtonTapped(newScale):
        let oldScale = Double(state.viewState.scale)
        state.viewState.scale = newScale
        let newScale = Double(state.viewState.scale)
        
        state.viewState.ingredients.indices.forEach { i in
          state.viewState.ingredients[i].viewState.ingredients.indices.forEach { j in
            let a = (state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount / oldScale) * newScale
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount = a
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
    var scale: Int = 1
    
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
      self.scale = 1
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

//        state.viewState.ingredients = .init(uniqueElements: ingredients.map { child in
//            .init(
//              id: .init(),
//              viewState: .init(
//                ingredientSection: .init(
//                  id: .init(),
//                  name: child.viewState.name,
//                  ingredients: .init(uniqueElements: child.viewState.ingredients.map { child in
//                      .init(
//                        id: .init(),
//                        name: child.viewState.ingredient.name,
//                        amount: (child.viewState.ingredient.amount / oldScale) * newScale,
//                        measure: child.viewState.ingredient.measure
//                      )
//                  })
//                ),
//                isExpanded: true
//              )
//            )
//        })
