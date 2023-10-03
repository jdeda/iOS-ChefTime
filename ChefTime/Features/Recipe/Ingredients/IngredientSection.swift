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
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
        ForEachStore(store.scope(
          state: \.ingredients,
          action: IngredientSectionReducer.Action.ingredient
        )) { childStore in
          let id = ViewStore(childStore, observe: \.id).state
          IngredientView(store: childStore)
            .onTapGesture {
              viewStore.send(.rowTapped(id))
            }
            .focused($focusedField, equals: .row(id))
          if let lastId = viewStore.ingredients.last?.id, lastId != id {
            Divider()
          }
        }
      } label: {
        TextField(
          "Untitled Ingredient Section",
          text: viewStore.binding(
            get: \.ingredientSection.name,
            send: { .ingredientSectionNameEdited($0) }
          ),
          axis: .vertical
        )
        .focused($focusedField, equals: .name)
        .textSubtitleStyle()
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
      .synchronize(viewStore.$focusedField, $focusedField)
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
struct IngredientSectionReducer: Reducer  {
  struct State: Equatable, Identifiable {
    var id: Recipe.IngredientSection.ID {
      self.ingredientSection.id
    }
    
    var ingredientSection: Recipe.IngredientSection
    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
    @BindingState var isExpanded: Bool
    @BindingState var focusedField: FocusField?
    
    init(ingredientSection: Recipe.IngredientSection, focusedField: FocusField? = nil) {
      self.ingredientSection = ingredientSection
      self.ingredients = ingredientSection.ingredients.map{ .init(ingredient: $0) }
      self.isExpanded = true
      self.focusedField = focusedField
    }
  }
  
  @Dependency(\.uuid) var uuid
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case ingredientSectionNameEdited(String)
    case ingredientSectionNameDoneButtonTapped
    case addIngredient
    case rowTapped(IngredientReducer.State.ID)
    case ingredientSectionsUpdate
    case delegate(DelegateAction)
  }
  
  @Dependency(\.continuousClock) var clock
  
  private enum AddIngredientID: Hashable { case timer }
  
  var body: some Reducer<IngredientSectionReducer.State, IngredientSectionReducer.Action> {
    BindingReducer()
    Reduce<IngredientSectionReducer.State, IngredientSectionReducer.Action> { state, action in
      switch action {
      case let .ingredient(id, .delegate(action)):
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
            ingredient: .init(id: .init(rawValue: uuid())),
            ingredientAmountString: "",
            focusedField: .name
          )
          state.ingredients.insert(s, at: aboveBelow == .above ? i : i + 1)
          state.focusedField = .row(s.id)
          return .none
        }
          
        case let .ingredientSectionNameEdited(newName):
        if state.ingredientSection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        if !state.ingredientSection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          state.ingredientSection.name = ""
          return .none
        }
        let didEnter = DidEnter.didEnter(state.ingredientSection.name, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.ingredientSection.name = newName
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
          ingredient: .init(id: .init(rawValue: uuid())),
          ingredientAmountString: "",
          focusedField: .name
        )
        state.ingredients.append(s)
        state.focusedField = .row(s.id)
        return .none
        
      case .ingredientSectionsUpdate:
        state.ingredientSection.ingredients = state.ingredientSection.ingredients
        return .none
        
      case .binding(\.$isExpanded):
        // If we just collapsed the list, nil out any potential focus state to prevent
        // keyboard issues such as duplicate buttons
        if !state.isExpanded {
          if case let .row(currId) = state.focusedField {
            state.ingredients[id: currId]?.focusedField = nil
          }
          state.focusedField = nil
        }
        return .none
        
      case .delegate, .binding, .ingredient:
        return .none
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
    .onChange(of: \.ingredients) { _, _ in
      Reduce { _, _ in
          .send(.ingredientSectionsUpdate)
      }
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
      Text(!state.ingredientSection.name.isEmpty ? state.ingredientSection.name : "Untitled Ingredient Section")
        .lineLimit(2)
        .textSubtitleStyle()
    }
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
            ingredientSection: Recipe.longMock.ingredientSections.first!
          ),
          reducer: IngredientSectionReducer.init
        ))
        .padding()
      }
    }
  }
}
