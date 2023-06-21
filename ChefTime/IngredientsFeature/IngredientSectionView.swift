import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: ContextMenu acts weird
// TODO: Scale causes ugly refresh
// TODO: Multiplier will format a sttring, but maybe we shold put a check in place
// if it is empty, keep the string...

// MARK: - View
struct IngredientSectionView: View {
  let store: StoreOf<IngredientSectionReducer>
  
  struct ViewState: Equatable {
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: IngredientSectionReducer.Destination.State?
    
    init(_ state: IngredientSectionReducer.State) {
      self.name = state.name
      self.ingredients = state.ingredients
      self.isExpanded = state.isExpanded
      self.destination = state.destination
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
          action: IngredientSectionReducer.Action.ingredient
        )) { childStore in
          IngredientView(store: childStore)
          Divider()
        }
        
        AddIngredientView()
          .onTapGesture {
            viewStore.send(.addIngredientButtonTapped, animation: .default)
          }
        Divider()
        
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
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
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
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: Destination.State?
    
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
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
    case deleteSectionButtonTapped
    case delegate(DelegateAction)
    case destination(PresentationAction<Destination.Action>)
    case addIngredientButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(delegateAction):
          switch delegateAction {
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
        
      case .deleteSectionButtonTapped:
        // TODO: Move this state elsewhere
        state.destination = .alert(.init(
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
        }
        
      case .addIngredientButtonTapped:
        // TODO: make this cleaner
        var s = IngredientReducer.State(
          id: .init(), // TODO: Make dependency
          ingredient: .init(
            id: .init(),
            name: "",
            amount: 0,
            measure: ""
          )
        )
        s.ingredientAmountString = ""
        state.ingredients.append(s)
        return .none
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
    .ifLet(\.$destination, action: CasePath(Action.destination)) {
      Destination()
    }
  }
  
  struct Destination: ReducerProtocol {
    enum State: Equatable {
      case alert(AlertState<AlertAction>)
      
    }
    enum Action: Equatable {
      case alert(AlertAction)
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
            ingredientSection: Recipe.longMock.ingredientSections[1],
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


// TODO: Make DiscloureGroupModifier
// 1. format label to have specific text styling
// 2. make entire group have primary accent color
// 3. make content have accent color accent color
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
      .frame(maxWidth : 50, maxHeight: .infinity, alignment: .trailing)
      .buttonStyle(.plain)
    }
    .contentShape(Rectangle())
    if configuration.isExpanded {
      configuration.content
        .disclosureGroupStyle(self)
    }
  }
}
