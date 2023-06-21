import SwiftUI
import ComposableArchitecture

// TODO: Section deletion has no animation
// TODO: Add a section

// MARK: - IngredientsListView
struct IngredientListPreview: View {
  let store: StoreOf<IngredientsListPreviewReducer>
  @State var string: String = ""
  
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionPreviewReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    var scaleString: String {
      switch scale {
      case 0.25: return "1/4"
      case 0.50: return "1/2"
      default:   return String(Int(scale))
      }
    }
    
    init(_ state: IngredientsListPreviewReducer.State) {
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
          action: IngredientsListPreviewReducer.Action.ingredient
        )) { childStore in
          IngredientSectionPreview(store: childStore)
        }
        
//        Divider()
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

// MARK: - IngredientsListPreviewReducer
struct IngredientsListPreviewReducer: ReducerProtocol {
  struct State: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionPreviewReducer.State>
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
    case ingredient(IngredientSectionPreviewReducer.State.ID, IngredientSectionPreviewReducer.Action)
    case isExpandedButtonToggled
    case scaleStepperButtonTapped(Double)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        return .none
        
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
      }
    }
    .forEach(\.ingredients, action: /Action.ingredient) {
      IngredientSectionPreviewReducer()
    }
    ._printChanges()
  }
}

// MARK: - Previews
struct IngredientListPreview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientListPreview(store: .init(
          initialState: .init(
            recipe: Recipe.longMock,
            isExpanded: true
          ),
          reducer: IngredientsListPreviewReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}


// MARK: --------------------------------

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

// MARK: --------------------------------

import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: Vertical Text Fields
// TODO: Swipe Gestures
// TODO: Number TextField still has bugs
//        1. fixed size means the row refreshes in a ugly way
//        2. typing invalid text still refreshes in a ugly way
//        3. sometimes editing another textfield moves text that
//           shouldn't move whatsoever

// MARK: - View
struct IngredientPreview: View {
  let store: StoreOf<IngredientPreviewReducer>
  
  struct ViewState: Equatable {
    var ingredient: Recipe.IngredientSection.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool
    
    init(_ state: IngredientPreviewReducer.State) {
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
            send: { _ in .none }
          ),
          axis: .vertical
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .disabled(true)
        
        // Amount
        TextField(
          "...",
          text: viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { _  in .none }
          )
        )
        .keyboardType(.numberPad)
        .numbersOnly(
          viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { _  in .none }
          ),
          includeDecimal: true
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .disabled(true)
        
        // Measurement
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.measure)" },
            send: { _  in .none }
          )
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .disabled(true)
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
    }
  }
}

// MARK: - Reducer
struct IngredientPreviewReducer: ReducerProtocol {
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
    case isCompleteButtonToggled
    case none
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .isCompleteButtonToggled:
        state.isComplete.toggle()
        return .none
        
      case .none:
        return .none
      }
    }
  }
}

// MARK: - Previews
struct IngredientPreviewView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView
      {
        IngredientPreview(store: .init(
          initialState: .init(
            id: .init(),
            ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!
          ),
          reducer: IngredientPreviewReducer.init,
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
