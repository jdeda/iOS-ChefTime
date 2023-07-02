import SwiftUI
import ComposableArchitecture

// TODO: Section deletion has no animation
// TODO: Section addition has no animation
// MARK: - IngredientsListView
struct IngredientListView: View {
  let store: StoreOf<IngredientsListReducer>
  @FocusState private var focusedField: IngredientsListReducer.FocusField?
    
  var body: some View {
    WithViewStore(store) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        IngredientStepper(scale: viewStore.binding(
          get: { $0.scale },
          send: { .scaleStepperButtonTapped($0) }
        ))
        
        ForEachStore(store.scope(
          state: \.ingredients,
          action: IngredientsListReducer.Action.ingredient
        )) { childStore in
          IngredientSection(store: childStore)
            .contentShape(Rectangle())
            .focused($focusedField, equals: .row(ViewStore(childStore).id))
          
          if ViewStore(childStore).isExpanded {
            Rectangle()
              .fill(.clear)
              .frame(height: 5)
          }
          
          if !ViewStore(childStore).isExpanded {
            Divider()
          }
        }
      }
      label : {
        Text("Ingredients")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .accentColor(.primary)
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
    }
  }
}

// MARK: - IngredientsListReducer
struct IngredientsListReducer: ReducerProtocol {
  struct State: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    @BindingState var focusedField: FocusField? = nil

    init(
      recipe: Recipe,
      isExpanded: Bool,
      childrenIsExpanded: Bool
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
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
    case isExpandedButtonToggled
    case scaleStepperButtonTapped(Double)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .deleteSectionButtonTapped:
            state.ingredients.remove(id: id)
            return .none
            
          case let .insertSection(aboveBelow):
            guard let i = state.ingredients.index(id: id)
            else { return .none }
            let newSection = IngredientSectionReducer.State(
              id: .init(),
              ingredientSection: .init(
                id: .init(),
                name: "",
                ingredients: []
              ),
              isExpanded: true,
              focusedField: .name
            )
            switch aboveBelow {
            case .above: state.ingredients.insert(newSection, at: i)
            case .below: state.ingredients.insert(newSection, at: i + 1)
            }
            state.focusedField = .row(newSection.id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .scaleStepperButtonTapped(newValue):
        let incremented = newValue > state.scale
        let oldScale = state.scale
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
        
        // TODO: Do this with ids...
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
        
      case .delegate, .binding:
        return .none
        
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientSectionReducer()
    }
  }
}

// MARK: - DelegateAction
extension IngredientsListReducer {
  enum DelegateAction {
    case sectionNavigationAreaTapped
  }
}

// MARK: - FocusField
extension IngredientsListReducer {
  enum FocusField: Equatable, Hashable {
    case row(IngredientSectionReducer.State.ID)
  }
}

// MARK: - Previews
struct IngredientList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientListView(store: .init(
          initialState: .init(
            recipe: Recipe.longMock,
            isExpanded: true,
            childrenIsExpanded: true
          ),
          reducer: IngredientsListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
