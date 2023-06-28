import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: Scale causes ugly refresh

// MARK: - View
struct IngredientSection: View {
  let store: StoreOf<IngredientSectionReducer>
  
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
          IngredientView(store: childStore)
          Divider()
        }
        
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
    
    init(id: ID, ingredientSection: Recipe.IngredientSection, isExpanded: Bool) {
      self.id = id
      self.name = ingredientSection.name
      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
        .init(id: .init(), ingredient: $0)
      }))
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable {
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .swipedToDelete:
            state.ingredients.remove(id: id)
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
        
      case .delegate:
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
