import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: Scale causes ugly refres

// TODO: - Bug - if focused on a row, then collapse, then click a row again, dupe buttons appear...
// getting a purple runtime error - A "forEach" at "ChefTime/IngredientSection.swift:211" received an action for a missing element. …
//
//Action:
//  IngredientSectionReducer.Action.ingredient(_:, _: .ingredientMeasureEdited)
//
//This is generally considered an application logic error, and can happen for a few reasons:
//
//• A parent reducer removed an element with this ID before this reducer ran. This reducer must run before any other reducer removes an element, which ensures that element reducers can handle their actions while their state is still available.
//
//• An in-flight effect emitted this action when state contained no element at this ID. While it may be perfectly reasonable to ignore this action, consider canceling the associated effect before an element is removed, especially if it is a long-living effect.
//
//• This action was sent to the store while its state contained no element at this ID. To fix this make sure that actions for this reducer can only be sent from a view store when its state contains an element at this id. In SwiftUI applications, use "ForEachStore".

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
        .onSubmit {
          viewStore.send(.ingredientSectionNameTextFieldSubmitted)
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
    
    
    init(
      id: ID,
      ingredientSection: Recipe.IngredientSection,
      isExpanded: Bool,
      focusedField: FocusField? = nil
    ) {
      self.id = id
      self.name = ingredientSection.name
      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
        .init(
          id: .init(),
          ingredient: $0,
          ingredientAmountString: String($0.amount)
        )
      }))
      self.isExpanded = isExpanded
      self.focusedField = focusedField
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
    case isExpandedButtonToggled
    case ingredientSectionNameEdited(String)
    case ingredientSectionNameTextFieldSubmitted
    case rowTapped(IngredientReducer.State.ID)
    case setFocusedField(FocusField)
    case delegate(DelegateAction)
  }
  
  @Dependency(\.continuousClock) var clock
  
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
            state.ingredients.remove(id: id)
            return .none
          case let .insertIngredient(aboveBelow):
            // Get the index and the ingredient.
            guard let i = state.ingredients.index(id: id),
                  let ingredient = state.ingredients[id: id]
            else { return .none }
            state.ingredients[id: id]?.focusedField = nil
            
            // Insert a new ingredient above or below it.
            let s = IngredientReducer.State.init(
              id: .init(),
              focusedField: .name,
              ingredient: .init(
                id: .init(),
                name: "",
                amount: 0.0,
                measure: ""
              ),
              ingredientAmountString: "",
              isComplete: false
            )
            switch aboveBelow {
            case .above: state.ingredients.insert(s, at: i)
            case .below: state.ingredients.insert(s, at: i + 1)
            }
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
        if state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return .none
        }
        // doesnt check if empty string
        let didEnter = didEnter(state.name, newName)
        switch didEnter {
        case .didNotSatisfy:
          state.name = newName
          return .none
        case .beginning, .end:
          state.focusedField = nil
          if state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .send(.delegate(.deleteSectionButtonTapped))
          }
          else {
            return .none
          }

        }
        
      case .ingredientSectionNameTextFieldSubmitted:
        state.focusedField = nil
        return .none
        
      case let .rowTapped(id):
        
        
        // Set the current selected row isSelected value to false.
        // This somehow causes an issue where all the focus in the section dies
        // and you have to click again...
        // Why?
        // We should be unfocusing the original one then setting focus to the newly activated one...
        // Unless this reducer runs twice
          if case let .row(currId) = state.focusedField {
            if currId == id { return .none }
            state.ingredients[id: currId]?.focusedField = nil
            return .run { send in
              try await clock.sleep(for: .microseconds(10))
              await send(.setFocusedField(.row(id)))
            }
          }
          return .none
        
      case let .setFocusedField(newFocusedField):
        state.focusedField = newFocusedField
        return .none
        
      case .delegate, .binding:
        return .none
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientReducer()
    }
    ._printChanges()
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

//import SwiftUI
//import ComposableArchitecture
//import Tagged
//
//// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
//// TODO: Scale causes ugly refresh
//
//// MARK: - View
//struct IngredientSection: View {
//  let store: StoreOf<IngredientSectionReducer>
//  @FocusState private var focusedField: IngredientSectionReducer.FocusField?
//
//  var body: some View {
//    WithViewStore(store) { viewStore in
//      DisclosureGroup(isExpanded: viewStore.binding(
//        get: { $0.isExpanded },
//        send: { _ in .isExpandedButtonToggled }
//      )) {
//        ForEachStore(store.scope(
//          state: \.ingredients,
//          action: IngredientSectionReducer.Action.ingredient
//        )) { childStore in
//          // Must make sure there is only one keyboard item at a time...
//          // We could do it here...
//          // Or we could add a property for the child view, that is immutable?
//          // But that may not be very clear to understand.
//          IngredientView(store: childStore)
//            .onTapGesture {
//              viewStore.send(.rowTapped(ViewStore(childStore).id))
//            }
//            .focused($focusedField, equals: .row(ViewStore(childStore).id))
//          Divider()
//        }
//      } label: {
//        TextField(
//          "Untitled Ingredient Section",
//          text: viewStore.binding(
//            get: \.name,
//            send: { .ingredientSectionNameEdited($0) }
//          ),
//          axis: .vertical
//        )
//        .font(.title3)
//        .fontWeight(.bold)
//        .foregroundColor(.primary)
//        .accentColor(.accentColor)
//        .frame(alignment: .leading)
//        .multilineTextAlignment(.leading)
//        .focused($focusedField, equals: .name)
//      }
//      .synchronize(viewStore.binding(\.$focusedField), $focusedField)
//      .disclosureGroupStyle(CustomDisclosureGroupStyle())
//      .accentColor(.primary)
//      .contextMenu {
//        Button {
//          viewStore.send(.delegate(.insertSection(.above)), animation: .default)
//        } label: {
//          Text("Insert Section Above")
//        }
//        Button {
//          viewStore.send(.delegate(.insertSection(.below)), animation: .default)
//        } label: {
//          Text("Insert Section Below")
//        }
//        Button(role: .destructive) {
//          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
//        } label: {
//          Text("Delete")
//        }
//      } preview: {
//        IngredientSectionContextMenuPreview(state: viewStore.state)
//          .frame(width: 200)
//          .padding()
//      }
//    }
//  }
//}
//
//// MARK: - Reducer
//struct IngredientSectionReducer: ReducerProtocol  {
//  struct State: Equatable, Identifiable {
//    typealias ID = Tagged<Self, UUID>
//
//    let id: ID
//    var name: String
//    var ingredients: IdentifiedArrayOf<IngredientReducer.State>
//    var isExpanded: Bool
//    @BindingState var focusedField: FocusField?
//
//
//    init(
//      id: ID,
//      ingredientSection: Recipe.IngredientSection,
//      isExpanded: Bool,
//      focusedField: FocusField? = nil
//    ) {
//      self.id = id
//      self.name = ingredientSection.name
//      self.ingredients = .init(uniqueElements: ingredientSection.ingredients.map({
//        .init(
//          id: .init(),
//          ingredient: $0,
//          ingredientAmountString: String($0.amount)
//        )
//      }))
//      self.isExpanded = isExpanded
//      self.focusedField = focusedField
//    }
//  }
//
//  enum Action: Equatable, BindableAction {
//    case binding(BindingAction<State>)
//    case ingredient(IngredientReducer.State.ID, IngredientReducer.Action)
//    case isExpandedButtonToggled
//    case ingredientSectionNameEdited(String)
//    case rowTapped(IngredientReducer.State.ID)
//    case delegate(DelegateAction)
//  }
//
//  var body: some ReducerProtocolOf<Self> {
//    BindingReducer()
//    Reduce { state, action in
//      switch action {
//      case let .ingredient(id, action):
//        switch action {
//        case let .delegate(action):
//          switch action {
//          case .swipedToDelete:
//            state.ingredients.remove(id: id)
//            return .none
//          case let .insertIngredient(above):
//            // Replace it with a new isSelected and focused field value.
//            state.ingredients[id: id]?.focusedField = nil
//
//            // Insert a new ingredient above or below it.
//            guard let i = state.ingredients.index(id: id) else { return .none }
//            let s = IngredientReducer.State.init(
//              id: .init(),
//              focusedField: .name,
//              ingredient: .init(
//                id: .init(),
//                name: "",
//                amount: 0.0,
//                measure: ""
//              ),
//              ingredientAmountString: "",
//              isComplete: false
//            )
//            switch above {
//              case .above: state.ingredients.insert(s, at: i)
//              case .below: state.ingredients.insert(s, at: i + 1)
//            }
//            state.focusedField = .row(s.id)
//            return .none
//          }
//        default:
//          return .none
//        }
//
//      case .isExpandedButtonToggled:
//        state.isExpanded.toggle()
//        return .none
//
//      case let .ingredientSectionNameEdited(newName):
//        state.name = newName
//        return .none
//
//      case let .rowTapped(id):
//        guard case let .row(currId) = state.focusedField else { return .none }
//        state.ingredients[id: currId]?.focusedField = nil
//        state.focusedField = .row(id)
//        return .none
//
//      case .delegate, .binding:
//        return .none
//      }
//    }
//    .forEach(\.ingredients, action: /Action.ingredient) {
//      IngredientReducer()
//    }
//  }
//}
//
//// MARK: - DelegateAction
//extension IngredientSectionReducer {
//  enum DelegateAction: Equatable {
//    case deleteSectionButtonTapped
//    case insertSection(AboveBelow)
//  }
//}
//
//// MARK: - FocusField
//extension IngredientSectionReducer {
//  enum FocusField: Equatable, Hashable {
//    case row(IngredientReducer.State.ID)
//    case name
//  }
//}
//
//
//// MARK: - IngredientSectionContextMenuPreview
//private struct IngredientSectionContextMenuPreview: View {
//  let state: IngredientSectionReducer.State
//
//  var body: some View {
//    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
//      ForEach(state.ingredients.prefix(5)) { ingredient in
//        IngredientContextMenuPreview(state: ingredient)
//        Divider()
//      }
//    } label: {
//      Text(!state.name.isEmpty ? state.name : "Untitled Ingredient Section")
//        .font(.title3)
//        .fontWeight(.bold)
//        .foregroundColor(.primary)
//        .accentColor(.accentColor)
//        .frame(alignment: .leading)
//        .multilineTextAlignment(.leading)
//    }
//    .disclosureGroupStyle(CustomDisclosureGroupStyle())
//    .accentColor(.primary)
//  }
//}
//
//// MARK: - Previews
//struct IngredientSection_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationStack {
//      ScrollView {
//        IngredientSection(store: .init(
//          initialState: .init(
//            id: .init(),
//            ingredientSection: Recipe.longMock.ingredientSections.first!,
//            isExpanded: true
//          ),
//          reducer: IngredientSectionReducer.init,
//          withDependencies: { _ in
//            // TODO:
//          }
//        ))
//        .padding()
//      }
//    }
//  }
//}
