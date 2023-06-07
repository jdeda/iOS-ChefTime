import SwiftUI
import ComposableArchitecture

// MARK: - IngredientsListView
struct IngredientsListView: View {
  let store: StoreOf<IngredientsListReducer>
  @State var string: String = ""
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: { $0.isExpanded },
        send: { _ in .isExpandedButtonToggled }
      )) {
        ForEachStore(store.scope(
          state: \.viewState.ingredients,
          action: IngredientsListReducer.Action.ingredient
        )) { childStore in
          IngredientSectionView(store: childStore)
        }
        // ...
      }
      label : {
        Text("Ingredients")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .accentColor(.primary)
    }
  }
}

// MARK: - IngredientsListReducer
struct IngredientsListReducer: ReducerProtocol {
  struct State: Equatable {
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredient(IngredientSectionReducer.State.ID, IngredientSectionReducer.Action)
    case isExpandedButtonToggled
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredient(id, action):
        return .none
        
      case .isExpandedButtonToggled:
        state.viewState.isExpanded.toggle()
        return .none
      }
    }
    .forEach(\.viewState.ingredients, action: /Action.ingredient) {
      IngredientSectionReducer()
    }
  }
}
extension IngredientsListReducer {
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<IngredientSectionReducer.State>
    var isExpanded: Bool
    var scale: Int = 1
    
    init(recipe: Recipe) {
      self.ingredients = .init(uniqueElements: recipe.ingredients.map({
        .init(
          id: .init(),
          viewState: .init(
            ingredientSection: .init(
              id: .init(),
              name: $0.name,
              ingredients: $0.ingredients
            ),
            isExpanded: true
          )
        )
      }))
      self.scale = 1
      self.isExpanded = true
    }
  }
}


// MARK: - Previews
struct IngredientsListView_Previews: PreviewProvider {
  static var previews: some View {  
    NavigationStack {
      ScrollView {
        IngredientsListView(store: .init(
          initialState: .init(
            viewState: .init(
              recipe: Recipe.mock
            )
          ),
          reducer: IngredientsListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .padding()
    }
  }
}



//import SwiftUI
//import ComposableArchitecture
//
/////
///// IngredientListActions
///// 1. add new ingredient sections
///// 2. swipe to delete ingredient sections
/////
///// IngredientSectionActions
///// 1. edit ingredient description
///// 2. toggle ingredient completion status
///// 3. add new ingredient
///// 4. swipe to delete delete ingredient
///// 5. multi select delete??
//
///// How to rename the section?
///// I would like to just treat it like a textfield...but how to model view?
/////
/////
/////   Recipe.IngredientSections
/////     - IngredientSection
/////         - Ingredient
/////         - Ingredient
/////         - Ingredient
/////     - IngredientSection
/////         - Ingredient
/////         - Ingredient
/////         - Ingredient
/////     - IngredientSection
/////         - Ingredient
/////         - Ingredient
/////         - Ingredient
//
//// MARK: - IngredientsListView
//struct IngredientsListView: View {
//  let store: StoreOf<IngredientsListReducer>
//  @State var string: String = ""
//
//  var body: some View {
//    WithViewStore(store, observe: \.viewState) { viewStore in
//      DisclosureGroup(isExpanded: .constant(true)) {
//        ForEach(viewStore.ingredients) { ingredients in
//          DisclosureGroup(isExpanded: .constant(true)) {
//            ForEach(ingredients.ingredients) { ingredient in
//              HStack {
//                Text(ingredient.name)
//                Spacer()
//              }
//            }
//          } label: {
//            Text(ingredients.name)
//              .font(.title3)
//              .fontWeight(.bold)
//              .foregroundColor(.primary)
//          }
//          .accentColor(.primary)
//        }
//      } label : {
//        Text("Ingredients")
//          .font(.title3)
//          .fontWeight(.bold)
//          .foregroundColor(.primary)
//      }
//      .accentColor(.primary)
//    }
//  }
//}
//
//struct IngredientsListView_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationStack {
//      ScrollView {
//        IngredientsListView(store: .init(
//          initialState: .init(viewState: .init(ingredients: Recipe.mock.ingredients)),
//          reducer: IngredientsListReducer.init,
//          withDependencies: { _ in
//            // TODO:
//          }
//        ))
//      }
//      .padding()
//    }
//  }
//}
//
//// MARK: - IngredientsListReducer
//struct IngredientsListReducer: ReducerProtocol {
//  struct State: Equatable {
//    var viewState: ViewState
//  }
//
//  enum Action: Equatable {
//    case ingredientSectionNameEdited(Recipe.Ingredients.ID, String)
//    case ingredientAmountEdited(Recipe.Ingredients.ID, Recipe.Ingredients.Ingredient.ID, String)
//    case incrementScaleButtonTapped
//    case decrementScaleButtonTapped
//    case scaleIngredients
//  }
//
//  var body: some ReducerProtocolOf<Self> {
//    Reduce { state, action in
//      switch action {
//      case let .ingredientSectionNameEdited(id, newName):
//        state.viewState.ingredients[id: id]?.name = newName
//        return .none
//
//      case let .ingredientAmountEdited(ingredientSectionId, ingredientId, newAmount):
////        if let newAmount = Double(newAmount) {
////          state.viewState.ingredients[id: ingredientSectionId]?.ingredients[id: ingredientId]?.amount = newAmount
////          return .none
////        }
////        else if let newAmount = Int(newAmount) {
////          let newAmount = Double(newAmount)
////          state.viewState.ingredients[id: ingredientSectionId]?.ingredients[id: ingredientId]?.amount = newAmount
////          return .none
////        }
//        guard let newAmount = Double(newAmount)
//        else { return .none }
//        state.viewState.ingredients[id: ingredientSectionId]?.ingredients[id: ingredientId]?.amount = newAmount
//        return .none
//
//      case .incrementScaleButtonTapped:
//        state.viewState.scale += 1
//        return .send(.scaleIngredients)
//
//      case .decrementScaleButtonTapped:
//        state.viewState.scale -= 1
//        return .send(.scaleIngredients)
//
//      case .scaleIngredients:
////        let old = state.viewState.ingredients
////        state.viewState.ingredients = .init(uniqueElements: state.viewState.ingredients.map { ingredients in
////          var newIngredients: Recipe.Ingredients = .init(
////            id: .init(),
////            name: ingredients.name,
////            ingredients: ingredients.ingredients
////          )
////          newIngredients.ingredients = .init(uniqueElements: newIngredients.ingredients.map { ingredient in
////            var newIngredient:  Recipe.Ingredients.Ingredient = .init(
////              id: .init(),
////              name: ingredient.name,
////              amount: ingredient.amount,
////              measure: ingredient.measure
////            )
////            newIngredient.amount *= Double(state.viewState.scale)
////            return newIngredient
////          })
////          return newIngredients
////        })
////        dump(old)
////        dump(state.viewState.ingredients)
//        return .none
//
////      case .scaleIngredients:
////        let old = state.viewState.ingredients
////        state.viewState.ingredients = .init(uniqueElements: state.viewState.ingredients.map { ingredients in
////          var newIngredients: Recipe.Ingredients = .init(
////            id: .init(),
////            name: ingredients.name,
////            ingredients: ingredients.ingredients
////          )
////          newIngredients.ingredients = .init(uniqueElements: newIngredients.ingredients.map { ingredient in
////            var newIngredient:  Recipe.Ingredients.Ingredient = .init(
////              id: .init(),
////              name: ingredient.name,
////              amount: ingredient.amount,
////              measure: ingredient.measure
////            )
////            newIngredient.amount *= Double(state.viewState.scale)
////            return newIngredient
////          })
////          return newIngredients
////        })
//////        dump(old)
//////        dump(state.viewState.ingredients)
////        return .none
//      }
//    }
//  }
//}
//extension IngredientsListReducer {
//  struct ViewState: Equatable {
//    var ingredients: IdentifiedArrayOf<Recipe.Ingredients>
//    var scale: Int = 1
//  }
//}
