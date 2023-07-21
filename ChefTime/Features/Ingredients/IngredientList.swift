import SwiftUI
import ComposableArchitecture

// MARK: - IngredientsListView
// TODO: Why is there a focus state
struct IngredientListView: View {
  let store: StoreOf<IngredientsListReducer>
  @FocusState private var focusedField: IngredientsListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      if viewStore.ingredients.isEmpty {
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
        .synchronize(viewStore.binding(\.$focusedField), $focusedField)
        .disclosureGroupStyle(CustomDisclosureGroupStyle()) // TODO: Make sure this is standardized!
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
    @BindingState var focusedField: FocusField? = nil
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
    case isExpandedButtonToggled
    case scaleStepperButtonTapped(Double)
    case addSectionButtonTapped
  }
  
  @Dependency(\.uuid) var uuid
  
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
            state.ingredients[i].focusedField = nil
            
            let newSection = IngredientSectionReducer.State(
              id: .init(rawValue: uuid()),
              name: "",
              ingredients: [],
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
        state.focusedField = nil
        // MARK: - W/O niling could end up with duplicate keyboard buttons due to conditional logic
        state.ingredients.ids.forEach { id1 in
          state.ingredients[id: id1]?.focusedField = nil
          state.ingredients[id: id1]?.ingredients.ids.forEach { id2 in
            state.ingredients[id: id1]?.ingredients[id: id2]?.focusedField = nil
          }
        }
        return .none
        
      case let .scaleStepperButtonTapped(newScale):
        let oldScale = state.scale
        state.scale = newScale
        for i in state.ingredients.indices {
          for j in state.ingredients[i].ingredients.indices { // TODO: Maybe do this with IDs and in parallel? :D
            let ingredient = state.ingredients[i].ingredients[j]
            guard !ingredient.ingredientAmountString.isEmpty else { continue }
            let amount = (ingredient.ingredient.amount / oldScale) * newScale
            let string = String(amount)
            state.ingredients[i].ingredients[j].ingredient.amount = amount
            state.ingredients[i].ingredients[j].ingredientAmountString = string
          }
        }
        return .none
        
      case .addSectionButtonTapped:
        let id = IngredientSectionReducer.State.ID(rawValue: uuid())
        state.ingredients.append(.init(
          id: id,
          name: "",
          ingredients: [],
          isExpanded: true,
          focusedField: .name
        ))
        state.focusedField = .row(id)
        return .none
        
      case .binding:
        return .none
        
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
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
        .font(.title3)
        .fontWeight(.bold)
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
            ingredients: .init(uniqueElements: Recipe.longMock.ingredientSections.map { section in
              .init(
                id: .init(),
                name: section.name,
                ingredients: .init(uniqueElements: (section.ingredients.map { ingredient in
                    .init(
                      id: .init(),
                      focusedField: nil,
                      ingredient: ingredient,
                      emptyIngredientAmountString: false
                    )
                })),
                isExpanded: true,
                focusedField: nil
              )
            }),
            isExpanded: true,
            scale: 1.0,
            focusedField: nil
          ),
          reducer: IngredientsListReducer.init
        ))
        .padding()
      }
    }
  }
}
