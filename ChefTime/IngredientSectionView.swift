import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: ContextMenu acts weird
// TODO: Scale causes ugly refresh

// MARK: - View
struct IngredientSectionView: View {
  let store: StoreOf<IngredientSectionReducer>
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.viewState.ingredients,
          action: IngredientSectionReducer.Action.ingredient
        )) { childStore in
          IngredientView(store: childStore)
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
      .contextMenu(menuItems: {
        Button(role: .destructive) {
          // TODO: - Lots of lag. The context menu is laggy...
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      }, preview: {
        IngredientSectionView(store: store)
          .padding()
      })
      .accentColor(.primary)
    }
  }
}
// TODO: context menu f'd up...
// selection should just highlight whole view not a row
// vertical textfield looks like shit

// MARK: - Reducer
struct IngredientSectionReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var viewState: ViewState
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
        case let .delegate(delegateAction):
          switch delegateAction {
          case .swipedToDelete:
            state.viewState.ingredients.remove(id: id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.viewState.isExpanded.toggle()
        return .none
        
      case let .ingredientSectionNameEdited(newName):
        state.viewState.name = newName
        return .none
        
      case .delegate:
        return .none
      }
    }
    .forEach(\.viewState.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
  }
}

extension IngredientSectionReducer {
  struct ViewState: Equatable {
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    
    init(ingredientSection: Recipe.Ingredients, isExpanded: Bool) {
      self.name = ingredientSection.name
      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
        .init(
          id: .init(),
          viewState: .init(
            ingredient: $0
          )
        )
      }))
      self.isExpanded = isExpanded
    }
  }
}

extension IngredientSectionReducer {
  enum DelegateAction: Equatable {
    case deleteSectionButtonTapped
  }
}

// MARK: - Previews
struct IngredientSectionView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientSectionView(store: .init(
          initialState: .init(
            id: .init(),
            viewState: .init(
              ingredientSection: Recipe.mock.ingredients[1],
              isExpanded: true
            )
          ),
          reducer: IngredientSectionReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .padding()
    }
  }
}


struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
      Spacer()
      Button {
        withAnimation {
          configuration.isExpanded.toggle()
        }
      } label: {
        Image(systemName: "chevron.right")
          .rotationEffect(configuration.isExpanded ? .degrees(90) : .degrees(0))
          .animation(.linear(duration: 0.3), value: configuration.isExpanded)
          .font(.caption)
          .fontWeight(.bold)
      }
      .frame(maxWidth: 50, maxHeight: .infinity, alignment: .trailing)
      .buttonStyle(.plain)
    }
    .contentShape(Rectangle())
    if configuration.isExpanded {
      configuration.content
        .disclosureGroupStyle(self)
    }
  }
}
