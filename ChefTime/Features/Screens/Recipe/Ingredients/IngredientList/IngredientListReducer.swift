import ComposableArchitecture

@Reducer
struct IngredientsListReducer {
  struct State: Equatable {
    var ingredientSections: IdentifiedArrayOf<IngredientSectionReducer.State> = []
    var scale: Double = 1.0
    @BindingState var isExpanded: Bool = true
    @BindingState var focusedField: FocusField? = nil
    
    init(recipeSections: IdentifiedArrayOf<Recipe.IngredientSection>) {
      self.ingredientSections = recipeSections.map { .init(ingredientSection: $0) }
    }
    
    var recipeSections: IdentifiedArrayOf<Recipe.IngredientSection> {
      ingredientSections
        .map { section in
          var section = section.ingredientSection
          section.ingredients = section.ingredients.map { ingredient in
            var ingredient = ingredient
            ingredient.amount /= scale
            return ingredient
          }
          return section
        }
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredientSections(IdentifiedActionOf<IngredientSectionReducer>)
    case scaleStepperButtonTapped(Double)
    case addSectionButtonTapped
  }
  
  @CasePathable
  @dynamicMemberLookup
  enum FocusField: Equatable, Hashable {
    case row(IngredientSectionReducer.State.ID)
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some Reducer<IngredientsListReducer.State, IngredientsListReducer.Action> {
    BindingReducer()
    Reduce<IngredientsListReducer.State, IngredientsListReducer.Action> { state, action in
      switch action {
      case let .ingredientSections(.element(id: id, action: .delegate(action))):
        switch action {
        case .deleteSectionButtonTapped:
          state.ingredientSections.remove(id: id)
          return .none
          
        case let .insertSection(aboveBelow):
          guard let i = state.ingredientSections.index(id: id)
          else { return .none }
          state.ingredientSections[i].focusedField = nil
          
          let newSection = IngredientSectionReducer.State(
            ingredientSection: .init(id: .init()),
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
        // TODO: Make this ID based...
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
          ingredientSection: .init(id: id),
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
        
      case .binding, .ingredientSections:
        return .none
        
      }
    }
    .forEach(\.ingredientSections, action: \.ingredientSections, element: IngredientSectionReducer.init)
  }
}
