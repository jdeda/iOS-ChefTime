import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: Scale causes ugly refresh

// MARK: - View
struct IngredientSection: View {
  let store: StoreOf<IngredientSectionReducer>
  @FocusState private var focusedField: IngredientSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.ingredients,
          action: IngredientSectionReducer.Action.ingredient
        )) { childStore in
          // Must make sure there is only one keyboard item at a time...
          // We could do it here...
          // Or we could add a property for the child view, that is immutable?
          // But that may not be very clear to understand.
          IngredientView(store: childStore)
            .focused($focusedField, equals: .row(ViewStore(childStore).id))
          Divider()
        }
        .animation(.default, value: viewStore.ingredients.count)
        
      } label: {
        TextField(
          "Untitled Ingredient Section",
          text: viewStore.binding(
            get: \.name,
            send: { .ingredientSectionNameEdited($0) }
          ),
          axis: .vertical
        )
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
      }
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
      .contextMenu {
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      } preview: {
        IngredientSectionContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

// MARK: - Reducer
struct IngredientSectionReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    @BindingState var focusedField: FocusField? = nil

    
    init(id: ID, ingredientSection: Recipe.IngredientSection, isExpanded: Bool) {
      self.id = id
      self.name = ingredientSection.name
      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
        .init(
          id: .init(),
          isSelected: false,
          ingredient: $0,
          ingredientAmountString: String($0.amount)
        )
      }))
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
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
          case .swipedToDelete:
            state.ingredients.remove(id: id)
            return .none
          case let .insertIngredient(above):
            // Get the index and the ingredient.
            guard let i = state.ingredients.index(id: id),
                  let ingredient = state.ingredients[id: id]
            else { return .none }
            
            // Replace it with a new isSelected and focused field value.
            state.ingredients.remove(at: i)
            let sOld = IngredientReducer.State(
              id: .init(),
              isSelected: false,
              focusedField: nil,
              ingredient: ingredient.ingredient,
              ingredientAmountString: ingredient.ingredientAmountString,
              isComplete: ingredient.isComplete
            )
            state.ingredients.insert(sOld, at: i)
            state.ingredients[id: id]?.focusedField = nil

            // Insert a new ingredient above or below it.
            let s = IngredientReducer.State.init(
              id: .init(),
              isSelected: true,
              focusedField: nil,
              ingredient: .init(
                id: .init(),
                name: "",
                amount: 0.0,
                measure: ""
              ),
              ingredientAmountString: "",
              isComplete: false
            )
            state.ingredients.insert(s, at: above ? i : i + 1)
            state.focusedField = .row(s.id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .ingredientSectionNameEdited(newName):
        state.name = newName
        return .none
        
      case .delegate, .binding:
        return .none
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
  }
}

extension IngredientSectionReducer {
  enum DelegateAction {
    case deleteSectionButtonTapped
  }
}


extension IngredientSectionReducer {
  enum FocusField: Equatable, Hashable {
    case row(IngredientReducer.State.ID)
  }
}

// MARK: - Previews
struct IngredientSection_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientSection(store: .init(
          initialState: .init(
            id: .init(),
            ingredientSection: Recipe.longMock.ingredientSections.first!,
            isExpanded: true
          ),
          reducer: IngredientSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}

// MARK: - IngredientSectionContextMenuPreview
private struct IngredientSectionContextMenuPreview: View {
  let state: IngredientSectionReducer.State
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      ForEach(state.ingredients.prefix(5)) { ingredient in
        IngredientContextMenuPreview(state: ingredient)
        Divider()
      }
    } label: {
      Text(!state.name.isEmpty ? state.name : "Untitled Ingredient Section")
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
    }
    .disclosureGroupStyle(CustomDisclosureGroupStyle())
    .accentColor(.primary)
  }
}
