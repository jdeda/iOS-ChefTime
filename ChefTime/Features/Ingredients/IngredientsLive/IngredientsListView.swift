import SwiftUI
import ComposableArchitecture

// TODO: Section deletion has no animation

// MARK: - IngredientsListView
struct IngredientListView: View {
  let store: StoreOf<IngredientsListReducer>
  
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    var scaleString: String {
      switch scale {
      case 0.25: return "1/4"
      case 0.50: return "1/2"
      default:   return String(Int(scale))
      }
    }
    
    init(_ state: IngredientsListReducer.State) {
      self.ingredients = state.ingredients
      self.scale = state.scale
      self.isExpanded = state.isExpanded
    }
  }
  
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
//      DisclosureGroup(isExpanded: viewStore.binding(
//        get: { $0.isExpanded },
//        send: { _ in .isExpandedButtonToggled }
//      )) {
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
          action: IngredientsListReducer.Action.ingredient
        )) { childStore in
          IngredientSectionView(store: childStore)
        }
//      }
//      label : {
//        Text("Ingredients")
//          .font(.title)
//          .fontWeight(.bold)
//          .foregroundColor(.primary)
//      }
//      .accentColor(.primary)
    }
  }
}

// MARK: - IngredientsListReducer
struct IngredientsListReducer: ReducerProtocol {
  struct State: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Double = 1.0
    
    init(recipe: Recipe, isExpanded: Bool, childrenIsExpanded: Bool) {
      self.ingredients = .init(uniqueElements: recipe.ingredientSections.map({
        .init(
          id: .init(),
          ingredientSection: .init(
            id: .init(),
            name: $0.name,
            ingredients: $0.ingredients
          ),
          isExpanded: childrenIsExpanded
        )
      }))
      self.scale = 1.0
      self.isExpanded = isExpanded
    }
  }
  enum Action: Equatable {
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
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
      IngredientSectionReducer()
    }
    ._printChanges()
  }
}

// MARK: - Previews
struct IngredientList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      List {
        IngredientListView(store: .init(
          initialState: .init(
            recipe: Recipe.longMock,
            isExpanded: true,
            childrenIsExpanded: true
          ),
          reducer: IngredientsListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .listStyle(.plain)
    }
  }
}


//import SwiftUI
//import ComposableArchitecture
//
//// List
//// item - edit
//// item - move
//// item - swipe to delete
//// item - multi-select delete
//// section - delete
//// section - move
//// section operations will require transformation of the view
//// into rows of sections, this will make things tricky
//// go find ur repo where u fixed the selection bug
//
//
//// MARK: - View
//struct IngredientsListViewView: View {
//  let store: StoreOf<IngredientsListViewReducer>
//
//  var body: some View {
//    WithViewStore(store, observe: { $0 }) { viewStore in
//      NavigationStack {
//        List(selection: viewStore.binding(
//          get: { $0.selection },
//          send: { _ in .selectionEdited }
//        )) {
//          ForEach(viewStore.sections) { section in
//            Section {
//              if viewStore.cTap {
//                ForEach(section.ingredients) { ingredient in
//                  IngredientViewX(ingredient: ingredient)
//                }
//              }
//            } header: {
//              HStack {
//                TextField(
//                  "Untitled Ingredient Section",
//                  text: .constant(section.name),
//                  axis: .vertical
//                )
//                .font(.title3)
//                .fontWeight(.bold)
//                .foregroundColor(.primary)
//                .accentColor(.accentColor)
//                .frame(alignment: .leading)
//                .multilineTextAlignment(.leading)
//                .disabled(true)
//
//                Spacer()
//                Image(systemName: "chevron.right")
//                  .rotationEffect(viewStore.cTap ? .degrees(90) : .degrees(0))
//                  .animation(.linear(duration: 0.3), value: viewStore.cTap)
//                  .font(.caption)
//                  .fontWeight(.bold)
//                  .onTapGesture {
//                    viewStore.send(.cTap, animation: .default)
//                  }
//              }
//            }
//          }
//        }
//        .navigationTitle("Ingredients")
//        .listStyle(.plain)
//        .toolbar {
//          ToolbarItemGroup(placement: .primaryAction) {
//            Button {
//              viewStore.send(.editButtonTapped)
//            } label: {
//              Image(systemName: "ellipsis.circle")
//            }
//          }
//        }
//        .environment(\.editMode, .constant(viewStore.isEditing ? .active : .inactive))
//        .animation(.default, value: viewStore.isEditing)
//      }
//    }
//  }
//}
//
//// MARK: - Reducer
//struct IngredientsListViewReducer: ReducerProtocol {
//  struct State: Equatable {
//    var sections: IdentifiedArrayOf<Recipe.IngredientSection>
//    var selection: Set<Recipe.IngredientSection.Ingredient.ID> = []
//    var isEditing: Bool = false
//    var isMoving: Bool = false
//    var cTap = true
//
//    var hasSelectedAll: Bool {
//      selection.count == sections.reduce(into: 0) { $0 + $1.ingredients.count }
//    }
//
//    var navigationBarTitle: String {
//      isEditing && selection.count > 0 ? "\(selection.count) Selected": "Ingredients"
//    }
//
//
//    init(recipe: Recipe) {
//      self.sections = recipe.ingredientSections
//    }
//  }
//
//  enum Action: Equatable {
//    case cTap
//    case editButtonTapped
//    case moveButtonTapped
//    case selectionEdited
//  }
//
//  var body: some ReducerProtocolOf<Self> {
//    Reduce { state, action in
//      switch action {
//      case .cTap:
//        state.cTap.toggle()
//        return .none
//
//      case .editButtonTapped:
//        state.isEditing.toggle()
//        return .none
//
//      case .moveButtonTapped:
//        return .none
//
//      case .selectionEdited:
//        return .none
//      }
//    }
//  }
//}
//
//// MARK: - Preview
//struct IngredientsListViewView_Previews: PreviewProvider {
//  static var previews: some View {
//    IngredientsListViewView(store: .init(
//      initialState: .init(recipe: .longMock),
//      reducer: IngredientsListViewReducer.init
//    ))
//  }
//}
//
//
//// MARK: - View
//struct IngredientViewX: View {
//  let ingredient: Recipe.IngredientSection.Ingredient
//  var body: some View {
//      HStack(alignment: .top) {
//
//        // Checkbox
//        Image(systemName: "square")
//          .fontWeight(.medium)
//          .padding([.top], 2)
//
//        // Name
//        TextField("...", text: .constant(ingredient.name), axis: .vertical)
//          .autocapitalization(.none)
//          .autocorrectionDisabled()
//          .disabled(true)
//
//        // Amount
//        TextField("...", text: .constant(String(ingredient.amount)))
//          .fixedSize()
//          .autocapitalization(.none)
//          .autocorrectionDisabled()
//          .disabled(true)
//
//        // Measurement
//        TextField( "...", text: .constant(ingredient.measure))
//          .fixedSize()
//          .autocapitalization(.none)
//          .autocorrectionDisabled()
//          .disabled(true)
//      }
//      .accentColor(.accentColor)
//  }
//}
