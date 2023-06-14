import SwiftUI
import ComposableArchitecture

// TODO: Section deletion has no animation
// TODO: Add a section

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
          in: 0.25...10.0,
          step: 1.0
        ) {
          Text("Servings \(viewStore.scaleString)")
            .font(.title3)
            .fontWeight(.bold)
        }
        
        ForEachStore(store.scope(
          state: \.viewState.ingredients,
          action: IngredientsListReducer.Action.ingredient
        )) { childStore in
          IngredientSectionView(store: childStore)
        }
        
        HStack {
          Text(" ")
          Spacer()
          Image(systemName: "plus")
            .font(.caption)
            .fontWeight(.bold)
            .onTapGesture {
              viewStore.send(.addIngredientSectionButtonTapped, animation: .default)
            }
        }
        .foregroundColor(.secondary)
        
        Divider()
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
    case scaleStepperButtonTapped(Double)
    case addIngredientSectionButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(delegateAction):
          switch delegateAction {
          case .deleteSectionButtonTapped:
            // TODO: Delete animation broken
            state.viewState.ingredients.remove(id: id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.viewState.isExpanded.toggle()
        return .none
        
      case let .scaleStepperButtonTapped(newValue):
        let incremented = newValue > state.viewState.scale
        let oldScale = state.viewState.scale
        let newScale: Double = {
          if incremented {
            switch oldScale {
            case 0.25: return 0.5
            case 0.5: return 1.0
            case 1.0..<10.0: return oldScale + 1
            default: return oldScale
            }
          }
          else {
            switch oldScale {
            case 0.25: return 0.25
            case 0.5: return 0.25
            case 1.0: return 0.5
            default: return oldScale - 1
            }
          }
        }()
        
        // TODO: Scaling causes text to move in ugly way.
        state.viewState.scale = newScale
        for i in state.viewState.ingredients.indices {
          for j in state.viewState.ingredients[i].viewState.ingredients.indices {
            let vs = state.viewState.ingredients[i].viewState.ingredients[j].viewState
            guard !vs.ingredientAmountString.isEmpty else { continue }
            let a = (vs.ingredient.amount / oldScale) * newScale
            let s = String(a)
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredient.amount = a
            state.viewState.ingredients[i].viewState.ingredients[j].viewState.ingredientAmountString = s
          }
        }
        return .none
        
      case .addIngredientSectionButtonTapped:
        state.viewState.ingredients.append(
          .init(
            id: .init(),
            viewState: .init(
              ingredientSection: .init(id: .init(), name: "New Ingredient Section", ingredients: []),
              isExpanded: true
            )
          ))
        return .none
      }
    }
    .forEach(\.viewState.ingredients, action: /Action.ingredient) {
      IngredientSectionReducer()
    }
    ._printChanges()
  }
}

extension IngredientsListReducer {
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    var scaleString: String {
      switch scale {
      case 0.25: return "1/4"
      case 0.50: return "1/2"
      default:   return String(Int(scale))
      }
    }
    
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
