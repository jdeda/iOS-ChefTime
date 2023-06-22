import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: ContextMenu acts weird
// TODO: Scale causes ugly refresh
// TODO: Multiplier will format a sttring, but maybe we shold put a check in place
// if it is empty, keep the string...

// MARK: - View
struct IngredientSectionPreview: View {
  let store: StoreOf<IngredientSectionPreviewReducer>
  
  struct ViewState: Equatable {
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientPreviewReducer.State>
    var isExpanded: Bool
    
    init(_ state: IngredientSectionPreviewReducer.State) {
      self.name = state.name
      self.ingredients = state.ingredients
      self.isExpanded = state.isExpanded
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.ingredients,
          action: IngredientSectionPreviewReducer.Action.ingredient
        )) { childStore in
          IngredientPreview(store: childStore)
          Divider()
        }
        
      } label: {
        TextField(
          "Untitled Ingredient Section",
          text: viewStore.binding(
            get: { $0.name},
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
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
    }
  }
}

// MARK: - Reducer
struct IngredientSectionPreviewReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientPreviewReducer.State>
    var isExpanded: Bool
    
    init(id: ID, ingredientSection: Recipe.IngredientSection, isExpanded: Bool) {
      self.id = id
      self.name = ingredientSection.name
      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
        .init(
          id: .init(),
          ingredient: $0
        )
      }))
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable {
    case ingredient(IngredientPreviewReducer.State.ID, IngredientPreviewReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        return .none
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .ingredientSectionNameEdited(newName):
        state.name = newName
        return .none
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientPreviewReducer()
    }
  }
}

// MARK: - Previews
struct IngredientSectionPreview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientSectionPreview(store: .init(
          initialState: .init(
            id: .init(),
            ingredientSection: Recipe.longMock.ingredientSections[1],
            isExpanded: true
          ),
          reducer: IngredientSectionPreviewReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
