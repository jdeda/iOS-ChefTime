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
          viewStore.send(.deleteSectionButtonTapped, animation: .default)
        } label: {
          Text("Delete")
        }
      }, preview: {
        IngredientSectionView(store: store)
          .padding()
      })
      .accentColor(.primary)
//      .confirmationDialog(
//        store: store.scope(state: \.viewState.$destination, action: { .destination($0) }),
//        state: /IngredientSectionReducer.Destination.State.confirmation,
//        action: IngredientSectionReducer.Destination.Action.confirmation
//      )
      
      .alert(
        store: store.scope(state: \.viewState.$destination, action: { .destination($0) }),
        state: /IngredientSectionReducer.Destination.State.alert,
        action: IngredientSectionReducer.Destination.Action.alert
      )

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
    case deleteSectionButtonTapped
    case delegate(DelegateAction)
    case destination(PresentationAction<Destination.Action>)
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
        
      case .deleteSectionButtonTapped:
//        state.viewState.destination = .confirmation(.init(
//          title: { TextState("Confirm Deletion")},
//          actions: {
//            .init(role: .destructive, action: .confirmSectionDeletion) {
//              TextState("Confirm")
//            }
//          },
//          message: {
//            TextState("Are you sure you want to delete this section?")
//          }
//        ))
        
        state.viewState.destination = .alert(.init(
          title: { TextState("Confirm Deletion")},
          actions: {
            .init(role: .destructive, action: .confirmSectionDeletion) {
              TextState("Confirm")
            }
          },
          message: {
            TextState("Are you sure you want to delete this section?")
          }
        ))
        return .none
        
      case .delegate:
        return .none
      
      case let .destination(action):
        switch action {
        case .presented(.alert(.confirmSectionDeletion)):
          return .send(.delegate(.deleteSectionButtonTapped), animation: .default)

        case .dismiss:
          return .none
          
        case .presented(.confirmation(.confirmSectionDeletion)):
          return .send(.delegate(.deleteSectionButtonTapped), animation: .default)
        }
        return .none
      }
    }
    .forEach(\.viewState.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
    .ifLet(\.viewState.$destination, action: CasePath(Action.destination)) {
      Destination()
    }
  }
  
  struct Destination: ReducerProtocol {
    enum State: Equatable {
      case alert(AlertState<AlertAction>)
      case confirmation(ConfirmationDialogState<AlertAction>)

    }
    enum Action: Equatable {
      case alert(AlertAction)
      case confirmation(AlertAction)
    }
    var body: some ReducerProtocolOf<Self> {
      EmptyReducer()
    }
  }
  
  enum AlertAction: Equatable {
    case confirmSectionDeletion
  }
}

extension IngredientSectionReducer {
  struct ViewState: Equatable {
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: Destination.State?
    
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
