import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: - Bug - if focused on a row, then collapse, then click a row again, dupe buttons appear...
// but sometimes if you tap another row, the dupe goes away, this does not work all the time
// this is all happening probably because we didn't nil out the focus state

// TODO: Fix the weird textfield behavior with spaces

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
            .onTapGesture {
              viewStore.send(.rowTapped(ViewStore(childStore).id))
            }
            .focused($focusedField, equals: .row(ViewStore(childStore).id))
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
        .lineLimit(.max)
        .focused($focusedField, equals: .name)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .toolbar {
          if viewStore.focusedField == .name {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button {
                viewStore.send(.ingredientSectionNameDoneButtonTapped)
              } label: {
                Text("done")
              }
            }
          }
        }
      }
      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
      .contextMenu {
        Button {
          viewStore.send(.delegate(.insertSection(.above)), animation: .default)
        } label: {
          Text("Insert Section Above")
        }
        Button {
          viewStore.send(.delegate(.insertSection(.below)), animation: .default)
        } label: {
          Text("Insert Section Below")
        }
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
    @BindingState var focusedField: FocusField?
  }
  
  // do i even need to test dependency in init?
  // i'd say yes because ur gonna have to assert
  // can i have two instance of dependencies?
  
  @Dependency(\.uuid) var uuid
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
    case ingredientSectionNameDoneButtonTapped
    case addIngredient
    case rowTapped(IngredientReducer.State.ID)
    case delegate(DelegateAction)
  }
  
  @Dependency(\.continuousClock) var clock
  
  private enum AddIngredientID: Hashable { case timer }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(action):
          switch action {
          case .tappedToDelete:
            // TODO: Animation can be a bit clunky, fix.
            if case let .row(currId) = state.focusedField, id == currId {
              state.focusedField = nil
            }
            state.ingredients.remove(id: id)
            return .none
            
          case let .insertIngredient(aboveBelow):
            guard let i = state.ingredients.index(id: id)
            else { return .none }
            state.ingredients[id: id]?.focusedField = nil
            let s = IngredientReducer.State.init(
              id: .init(rawValue: uuid()),
              focusedField: .name,
              ingredient: .init(id: .init(rawValue: uuid()))
            )
            state.ingredients.insert(s, at: aboveBelow == .above ? i : i + 1)
            state.focusedField = .row(s.id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        if case let .row(currId) = state.focusedField {
          state.ingredients[id: currId]?.focusedField = nil
        }
        state.focusedField = nil
        return .none
        
      case let .ingredientSectionNameEdited(newName):
        if state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        let didEnter = DidEnter.didEnter(state.name, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.name = newName
          return .none
        case .leading, .trailing:
          state.focusedField = nil
          if !state.ingredients.isEmpty { return .none }
          else {
            /// MARK: - There is a strange bug where if this action is not sent asynchronously for an
            /// extremely brief moment, the focus does not focus, This might be some strange bug with focus
            /// maybe the .synchronize doesn't react properly. Regardless this very short sleep fixes the problem.
            /// This effect is also debounced to prevent multi additons as this action may be called from the a TextField
            /// which always emits twice when interacted with, which is a SwiftUI behavior:
            return .run { send in
              try await self.clock.sleep(for: .microseconds(10))
              await send(.addIngredient, animation: .default)
            }
            .cancellable(id: AddIngredientID.timer, cancelInFlight: true)
          }
        }
        
      case .ingredientSectionNameDoneButtonTapped:
        state.focusedField = nil
        return .none
        
      case let .rowTapped(id):
        state.focusedField = .row(id)
        return .none
        
      case .addIngredient:
        let s = IngredientReducer.State(
          id: .init(rawValue: uuid()),
          focusedField: .name,
          ingredient: .init(id: .init(rawValue: uuid()))
        )
        state.ingredients.append(s)
        state.focusedField = .row(s.id)
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

// MARK: - DelegateAction
extension IngredientSectionReducer {
  enum DelegateAction: Equatable {
    case deleteSectionButtonTapped
    case insertSection(AboveBelow)
  }
}

// MARK: - FocusField
extension IngredientSectionReducer {
  enum FocusField: Equatable, Hashable {
    case row(IngredientReducer.State.ID)
    case name
  }
}


// MARK: - IngredientSectionContextMenuPreview
private struct IngredientSectionContextMenuPreview: View {
  let state: IngredientSectionReducer.State
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      ForEach(state.ingredients.prefix(4)) { ingredient in
        IngredientContextMenuPreview(state: ingredient)
        Divider()
      }
    } label: {
      Text(!state.name.isEmpty ? state.name : "Untitled Ingredient Section")
        .lineLimit(2)
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

// MARK: - Previews
struct IngredientSection_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientSection(store: .init(
          initialState: .init(
            id: .init(),
            name: Recipe.longMock.ingredientSections.first!.name,
            ingredients: .init(uniqueElements: Recipe.longMock.ingredientSections.first!.ingredients.map {
              .init(
                id: .init(),
                focusedField: nil,
                ingredient: $0,
                emptyIngredientAmountString: false
              )
            }),
            isExpanded: true,
            focusedField: nil
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
