import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: Section deletion has no animation
// TODO: Add a section

// MARK: - IngredientsListLiveView
struct IngredientsListLiveView: View {
  let store: StoreOf<IngredientsListLiveReducer>
  @State var string: String = ""
  
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionLiveReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    var scaleString: String {
      switch scale {
      case 0.25: return "1/4"
      case 0.50: return "1/2"
      default:   return String(Int(scale))
      }
    }
    
    init(_ state: IngredientsListLiveReducer.State) {
      self.ingredients = state.ingredients
      self.scale = state.scale
      self.isExpanded = state.isExpanded
    }
  }
  
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        Stepper(
          value: viewStore.binding(
            get: { $0.scale },
            send: { .scaleStepperButtonTapped($0) }
          ),
          in: 0.25...10.0,
          step: 1.0
        ) {
          Text("Servings \(viewStore.scaleString)")
            .font(.title3)
            .fontWeight(.bold)
        }
        
        ForEachStore(store.scope(
          state: \.ingredients,
          action: IngredientsListLiveReducer.Action.ingredient
        )) { childStore in
          IngredientSectionLiveView(store: childStore)
        }
        
        HStack {
          Text(" ")
          Spacer()
          Image(systemName: "plus")
            .font(.caption)
            .fontWeight(.bold)
            .onTapGesture {
              viewStore.send(.addIngredientSectionButtonTapped, animation: .default)
            }
        }
        .foregroundColor(.secondary)
        
        Divider()
      }
      label : {
        Text("Ingredients")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
    }
  }
}

// MARK: - IngredientsListLiveReducer
struct IngredientsListLiveReducer: ReducerProtocol {
  struct State: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionLiveReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    init(recipe: Recipe, isExpanded: Bool) {
      self.ingredients = .init(uniqueElements: recipe.ingredientSections.map({
        .init(
          id: .init(),
          ingredientSection: .init(
            id: .init(),
            name: $0.name,
            ingredients: $0.ingredients
          ),
          isExpanded: true
        )
      }))
      self.scale = 1.0
      self.isExpanded = isExpanded
    }
  }
  enum Action: Equatable {
    case ingredient(IngredientSectionLiveReducer.State.ID, IngredientSectionLiveReducer.Action)
    case isExpandedButtonToggled
    case scaleStepperButtonTapped(Double)
    case addIngredientSectionButtonTapped
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        switch action {
        case let .delegate(delegateAction):
          switch delegateAction {
          case .deleteSectionButtonTapped:
            // TODO: Delete animation broken
            state.ingredients.remove(id: id)
            return .none
          }
        default:
          return .none
        }
        
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .scaleStepperButtonTapped(newValue):
        let incremented = newValue > state.scale
        let oldScale = state.scale
        let newScale: Double = {
          if incremented {
            switch oldScale {
            case 0.25: return 0.5
            case 0.5: return 1.0
            case 1.0..<10.0: return oldScale + 1
            default: return oldScale
            }
          }
          else {
            switch oldScale {
            case 0.25: return 0.25
            case 0.5: return 0.25
            case 1.0: return 0.5
            default: return oldScale - 1
            }
          }
        }()
        
        // TODO: Scaling causes text to move in ugly way.
        state.scale = newScale
        for i in state.ingredients.indices {
          for j in state.ingredients[i].ingredients.indices {
            let vs = state.ingredients[i].ingredients[j]
            guard !vs.ingredientAmountString.isEmpty else { continue }
            let a = (vs.ingredient.amount / oldScale) * newScale
            let s = String(a)
            state.ingredients[i].ingredients[j].ingredient.amount = a
            state.ingredients[i].ingredients[j].ingredientAmountString = s
          }
        }
        return .none
        
      case .addIngredientSectionButtonTapped:
        state.ingredients.append(
          .init(
            id: .init(),
            ingredientSection: .init(id: .init(), name: "New Ingredient Section", ingredients: []),
            isExpanded: true
          )
        )
        return .none
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientSectionLiveReducer()
    }
    ._printChanges()
  }
}

// MARK: - Previews
struct IngredientsListLiveView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientsListLiveView(store: .init(
          initialState: .init(
            recipe: Recipe.mock,
            isExpanded: true
          ),
          reducer: IngredientsListLiveReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}

//////////////////////////////////////


// TODO: ingredient textfield name moves when expansions change, this happens almost every time with multi-line text
// TODO: ContextMenu acts weird
// TODO: Scale causes ugly refresh
// TODO: Multiplier will format a sttring, but maybe we shold put a check in place
// if it is empty, keep the string...

// MARK: - View
struct IngredientSectionLiveView: View {
  let store: StoreOf<IngredientSectionLiveReducer>
  
  struct ViewState: Equatable {
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientLiveReducer.State>
    var isExpanded: Bool
    @PresentationState var destination: IngredientSectionLiveReducer.Destination.State?
    
    init(_ state: IngredientSectionLiveReducer.State) {
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
          action: IngredientSectionLiveReducer.Action.ingredient
        )) { childStore in
          IngredientLiveVew(store: childStore)
          Divider()
        }
        
        AddIngredientLiveVew()
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
        IngredientSectionLiveView(store: store)
          .padding()
      })
      .accentColor(.primary)
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
        state: /IngredientSectionLiveReducer.Destination.State.alert,
        action: IngredientSectionLiveReducer.Destination.Action.alert
      )
    }
  }
}

// TODO: context menu f'd up...
// selection should just highlight whole view not a row
// vertical textfield looks like shit

// MARK: - Reducer
struct IngredientSectionLiveReducer: ReducerProtocol  {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var name: String
    var ingredients: IdentifiedArrayOf<IngredientLiveReducer.State>
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
    case ingredient(IngredientLiveReducer.State.ID, IngredientLiveReducer.Action)
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
        var s = IngredientLiveReducer.State(
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
      IngredientLiveReducer()
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

extension IngredientSectionLiveReducer {
  enum DelegateAction: Equatable {
    case deleteSectionButtonTapped
  }
}

// MARK: - Previews
struct IngredientSectionLiveView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientSectionLiveView(store: .init(
          initialState: .init(
            id: .init(),
            ingredientSection: Recipe.mock.ingredientSections[1],
            isExpanded: true
          ),
          reducer: IngredientSectionLiveReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}


/////////////

// TODO: Vertical Text Fields
// TODO: Swipe Gestures
// TODO: Number TextField still has bugs
//        1. fixed size means the row refreshes in a ugly way
//        2. typing invalid text still refreshes in a ugly way
//        3. sometimes editing another textfield moves text that
//           shouldn't move whatsoever

// MARK: - View
struct IngredientLiveVew: View {
  let store: StoreOf<IngredientLiveReducer>
  
  struct ViewState: Equatable {
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool
    
    init(_ state: IngredientLiveReducer.State) {
      self.ingredient = state.ingredient
      self.ingredientAmountString = state.ingredientAmountString
      self.isComplete = state.isComplete
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      HStack(alignment: .top) {
        
        // Checkbox
        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
          .fontWeight(.medium)
          .onTapGesture {
            viewStore.send(.isCompleteButtonToggled)
          }
          .padding([.top], 2)
        
        // Name
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.name)" },
            send: { .ingredientNameEdited($0) }
          ),
          axis: .vertical
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        // Amount
        TextField(
          "...",
          text: viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { .ingredientAmountEdited($0) }
          )
        )
        .keyboardType(.numberPad)
        .numbersOnly(
          viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { .ingredientAmountEdited($0) }
          ),
          includeDecimal: true
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        // Measurement
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.measure)" },
            send: { .ingredientMeasureEdited($0) }
          )
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
      .contextMenu {
        // TODO: This would be nice as a swipe action.
        Button(role: .destructive){
          viewStore.send(.delegate(.swipedToDelete), animation: .default)
        } label: {
          Text("Delete")
        }
      }
    }
  }
}

// MARK: - Reducer
struct IngredientLiveReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool = false
    
    init(id: ID, ingredient: Recipe.IngredientSection.Ingredient) {
      self.id = id
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
    }
  }
  
  enum Action: Equatable {
    case ingredientNameEdited(String)
    case ingredientAmountEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .ingredientNameEdited(newName):
        state.ingredient.name = newName
        return .none
        
      case let .ingredientAmountEdited(newAmountString):
        // TODO: Fix...
        state.ingredientAmountString = newAmountString
        state.ingredient.amount = Double(newAmountString) ?? 0
        return .none
        
      case let .ingredientMeasureEdited(newMeasure):
        state.ingredient.measure = newMeasure
        return .none
        
      case .isCompleteButtonToggled:
        state.isComplete.toggle()
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

extension IngredientLiveReducer {
  enum DelegateAction: Equatable {
    case swipedToDelete
  }
}

// MARK: - Previews
struct IngredientLiveVew_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView
      {
        IngredientLiveVew(store: .init(
          initialState: .init(
            id: .init(),
            ingredient: Recipe.mock.ingredientSections.first!.ingredients.first!
          ),
          reducer: IngredientLiveReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}

// MARK: - NumbersOnlyViewModifier (Private)
private struct NumbersOnlyViewModifier: ViewModifier {
  @Binding var text: String
  var includeDecimal: Bool
  
  func body(content: Content) -> some View {
    content
      .keyboardType(includeDecimal ? .decimalPad : .numberPad)
      .onReceive(Just(text)) { newValue in
        var numbers = "0123456789"
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        if includeDecimal {
          numbers += decimalSeparator
        }
        if newValue.components(separatedBy: decimalSeparator).count-1 > 1 {
          let filtered = newValue
          self.text = String(filtered.dropLast())
        }
        else {
          let filtered = newValue.filter { numbers.contains($0) }
          if filtered != newValue {
            self.text = filtered
          }
        }
      }
  }
}

private extension View {
  func numbersOnly(_ text: Binding<String>, includeDecimal: Bool = false) -> some View {
    self.modifier(NumbersOnlyViewModifier(text: text, includeDecimal: includeDecimal))
  }
}

struct AddIngredientLiveVew: View {
  var body: some View {
    HStack(alignment: .top) {
      
      // Checkbox
      Image(systemName: "square")
        .fontWeight(.medium)
        .padding([.top], 2)
      
      // Name
      TextField("...", text: .constant(""))
        .disabled(true)
      
      // Amount
      TextField("...", text: .constant(""))
        .disabled(true)
        .fixedSize()
      
      // Measurement
      TextField("...", text: .constant(""))
        .disabled(true)
        .fixedSize()
      
      Image(systemName: "plus")
        .fontWeight(.medium)
        .padding([.top], 2)
    }
    .foregroundColor(.secondary)
    .accentColor(.accentColor)
  }
}

