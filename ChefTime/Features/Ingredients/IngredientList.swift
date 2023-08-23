import SwiftUI
import ComposableArchitecture

// MARK: - IngredientsListView
// TODO: Why is there a focus state
struct IngredientListView: View {
  let store: StoreOf<IngredientsListReducer>
  @FocusState private var focusedField: IngredientsListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      if viewStore.ingredientSections.isEmpty {
        VStack {
          HStack {
            Text("Ingredients")
              .textTitleStyle()
            Spacer()
          }
          HStack {
            TextField(
              "Untitled Ingredient Section",
              text: .constant(""),
              axis: .vertical
            )
            .textSubtitleStyle()
            Spacer()
            Image(systemName: "plus")
          }
          .foregroundColor(.secondary)
          .onTapGesture {
            viewStore.send(.addSectionButtonTapped, animation: .default)
          }
        }
      }
      else {
        DisclosureGroup(isExpanded: viewStore.$isExpanded) {
          IngredientStepper(scale: viewStore.binding(
            get: { $0.scale },
            send: { .scaleStepperButtonTapped($0) }
          ))
          
          ForEachStore(store.scope(
            state: \.ingredientSections,
            action: IngredientsListReducer.Action.ingredient
          )) { childStore in
            IngredientSection(store: childStore)
              .contentShape(Rectangle())
              .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
            Divider()
              .padding(.bottom, 5)
          }
        }
        label : {
          Text("Ingredients")
            .textTitleStyle()
          Spacer()
        }
        .accentColor(.primary)
        .synchronize(viewStore.$focusedField, $focusedField)
        .disclosureGroupStyle(CustomDisclosureGroupStyle()) // TODO: Make sure this is standardized!
      }
    }
  }
}

// MARK: - IngredientsListReducer
struct IngredientsListReducer: Reducer {
  struct State: Equatable {
    
    var ingredientSections: IdentifiedArrayOf<IngredientSectionReducer.State>
    var scale: Double = 1.0
    @BindingState var isExpanded: Bool
    @BindingState var focusedField: FocusField? = nil
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
    case scaleStepperButtonTapped(Double)
    case addSectionButtonTapped
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .ingredient(id, .delegate(action)):
        switch action {
        case .deleteSectionButtonTapped:
          state.ingredientSections.remove(id: id)
          return .none
          
        case let .insertSection(aboveBelow):
          guard let i = state.ingredientSections.index(id: id)
          else { return .none }
          state.ingredientSections[i].focusedField = nil
          
          let newSection = IngredientSectionReducer.State(
            id: .init(rawValue: uuid()),
            name: "",
            ingredients: [],
            isExpanded: true,
            focusedField: .name
          )
          switch aboveBelow {
          case .above: state.ingredientSections.insert(newSection, at: i)
          case .below: state.ingredientSections.insert(newSection, at: i + 1)
          }
          state.focusedField = .row(newSection.id)
          return .none
        }
        
      case let .scaleStepperButtonTapped(newScale):
        let oldScale = state.scale
        state.scale = newScale
        for i in state.ingredientSections.indices {
          for j in state.ingredientSections[i].ingredients.indices {
            let ingredient = state.ingredientSections[i].ingredients[j]
            guard !ingredient.ingredientAmountString.isEmpty else { continue }
            let amount = (ingredient.ingredient.amount / oldScale) * newScale
            let string = String(amount)
            state.ingredientSections[i].ingredients[j].ingredient.amount = amount
            state.ingredientSections[i].ingredients[j].ingredientAmountString = string
          }
        }
        return .none
        
      case .addSectionButtonTapped:
        let id = IngredientSectionReducer.State.ID(rawValue: uuid())
        state.ingredientSections.append(.init(
          id: id,
          name: "",
          ingredients: [],
          isExpanded: true,
          focusedField: .name
        ))
        state.focusedField = .row(id)
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          state.focusedField = nil
          state.ingredientSections.ids.forEach { id1 in
            state.ingredientSections[id: id1]?.focusedField = nil
            state.ingredientSections[id: id1]?.ingredients.ids.forEach { id2 in
              state.ingredientSections[id: id1]?.ingredients[id: id2]?.focusedField = nil
            }
          }
        }
        return .none
        
      case .binding, .ingredient:
        return .none
        
      }
    }
    .forEach(\.ingredientSections, action: /Action.ingredient) {
      IngredientSectionReducer()
    }
  }
}

// MARK: - FocusField
extension IngredientsListReducer {
  enum FocusField: Equatable, Hashable {
    case row(IngredientSectionReducer.State.ID)
  }
}


// MARK: - IngredientStepper
private struct IngredientStepper: View {
  @Binding var scale: Double
  
  var scaleString: String {
    switch scale {
    case 0.25: return "1/4"
    case 0.50: return "1/2"
    default:   return String(Int(scale))
    }
  }
  
  var body: some View {
    Stepper(
      value: .init(
        get: { scale },
        set: { scaleStepperButtonTapped($0) }
      ),
      in: 0.25...10.0,
      step: 1.0
    ) {
      Text("Servings \(scaleString)")
        .textSubtitleStyle()
    }
  }
  
  func scaleStepperButtonTapped(_ newScale: Double) {
    let incremented = newScale > scale
    let oldScale = scale
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
    scale = newScale
  }
}

// MARK: - Previews
struct IngredientList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientListView(store: .init(
          initialState: .init(
            ingredientSections: .init(uniqueElements: Recipe.longMock.ingredientSections.map { section in
                .init(
                  id: .init(),
                  name: section.name,
                  ingredients: .init(uniqueElements: (section.ingredients.map { ingredient in
                      .init(
                        id: .init(),
                        ingredient: ingredient,
                        ingredientAmountString: String(ingredient.amount),
                        focusedField: nil
                      )
                  })),
                  isExpanded: true,
                  focusedField: nil
                )
            }),
            isExpanded: true,
            focusedField: nil
          ),
          reducer: IngredientsListReducer.init
        ))
        .padding()
      }
    }
  }
}
