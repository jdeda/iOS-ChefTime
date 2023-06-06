import SwiftUI
import ComposableArchitecture

///
/// IngredientListActions
/// 1. add new ingredient sections
/// 2. swipe to delete ingredient sections
///
/// IngredientSectionActions
/// 1. edit ingredient description
/// 2. toggle ingredient completion status
/// 3. add new ingredient
/// 4. swipe to delete delete ingredient
/// 5. multi select delete??

/// How to rename the section?
/// I would like to just treat it like a textfield...but how to model view?

// MARK: - IngredientsListView
struct IngredientsListView: View {
  let store: StoreOf<IngredientsListReducer>
  @State var string: String = ""
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      // Ingredients.
      MyCollapsible(collapsed: false) {
        Text("Ingredients")
          .font(.title)
          .fontWeight(.bold)
      } content: {
          Stepper(
            "Scale \(viewStore.scale)",
            value: viewStore.binding(
              get: { $0.scale },
              send: { $0 > viewStore.scale ? .incrementScaleButtonTapped : .decrementScaleButtonTapped }
            ), in: 1...100
          )
        ForEach(viewStore.ingredients) { ingredients in
          MyCollapsible2(collapsed: false) {
            TextField(ingredients.name, text: viewStore.binding(
              get: { viewState in
                viewState.ingredients[id: ingredients.id]?.name ?? ingredients.name
              },
              send: { newName in
                  .ingredientSectionNameEdited(ingredients.id, newName)
              }
            ))
              .foregroundColor(.primary)
              .font(.title3)
              .fontWeight(.bold)
              .frame(maxWidth: CGFloat((ingredients.name.count * 10) + 10))
          } content: {
            ForEach(viewStore.ingredients[id: ingredients.id]!.ingredients.ingredients) { ingredient in
              HStack {
//                HStack(alignment: .top) {
//                  Image(systemName: ingredient.amount == 2 ? "checkmark.square" : "square")
//                    .resizable()
//                    .frame(width: 15, height: 15)
//                    .padding([.top], 4)
//
//                  Text("\(Int(ingredient.amount)) \(ingredient.measure) \(ingredient.name)")
//                    .fontWeight(.medium)
//                }
                HStack(alignment: .top) {
                  VStack(alignment: .leading, spacing: 5) {
                    Text("\(ingredient.name)")
                      .fontWeight(.medium)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                      TextField("\(ingredient.amount * Double(viewStore.scale))", text: viewStore.binding(
                        get: { "\(($0.ingredients[id: ingredients.id]?.ingredients[id: ingredient.id]?.amount ?? ingredient.amount) * Double($0.scale))" },
                        send: { .ingredientAmountEdited(ingredients.id, ingredient.id, $0) }
                      ))
//                        .frame(width: CGFloat((String(ingredient.amount).count * 10) + 10))
                        .keyboardType(.numberPad)
                      TextField("\(ingredient.measure)", text: .constant("\(ingredient.measure)"))
//                        .frame(width: CGFloat((ingredient.measure.count * 10)) + 10)
                      Spacer()
                    }
                    .fontWeight(.medium)
                  }
                  Spacer()
                  Image(systemName: ingredient.amount == 2 ? "checkmark.square" : "square")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding([.top], 4)
                }
                .foregroundColor(ingredient.amount == 2 ? .secondary : .primary)
                Spacer()
              }
              Divider()
            }
          }
//          MyCollapsible2(collapsed: false) {
//            TextField(ingredients.name, text: viewStore.binding(
//              get: { viewState in
//                viewState.ingredients[id: ingredients.id]?.name ?? ingredients.name
//              },
//              send: { newName in
//                  .ingredientSectionNameEdited(ingredients.id, newName)
//              }
//            ))
//              .foregroundColor(.primary)
//              .font(.title3)
//              .fontWeight(.bold)
//              .frame(maxWidth: CGFloat((ingredients.name.count * 10) + 10))
//          } content: {
//            ForEach(ingredients.ingredients) { ingredient in
//              HStack {
////                HStack(alignment: .top) {
////                  Image(systemName: ingredient.amount == 2 ? "checkmark.square" : "square")
////                    .resizable()
////                    .frame(width: 15, height: 15)
////                    .padding([.top], 4)
////
////                  Text("\(Int(ingredient.amount)) \(ingredient.measure) \(ingredient.name)")
////                    .fontWeight(.medium)
////                }
//                HStack(alignment: .top) {
//                  VStack(alignment: .leading, spacing: 5) {
//                    Text("\(ingredient.name)")
//                      .fontWeight(.medium)
//                    HStack(alignment: .firstTextBaseline, spacing: 0) {
//                      TextField("\(ingredient.amount * Double(viewStore.scale))", text: viewStore.binding(
//                        get: { "\(($0.ingredients[id: ingredients.id]?.ingredients[id: ingredient.id]?.amount ?? ingredient.amount) * Double($0.scale))" },
//                        send: { .ingredientAmountEdited(ingredients.id, ingredient.id, $0) }
//                      ))
////                        .frame(width: CGFloat((String(ingredient.amount).count * 10) + 10))
//                        .keyboardType(.numberPad)
//                      TextField("\(ingredient.measure)", text: .constant("\(ingredient.measure)"))
////                        .frame(width: CGFloat((ingredient.measure.count * 10)) + 10)
//                      Spacer()
//                    }
//                    .fontWeight(.medium)
//                  }
//                  Spacer()
//                  Image(systemName: ingredient.amount == 2 ? "checkmark.square" : "square")
//                    .resizable()
//                    .frame(width: 15, height: 15)
//                    .padding([.top], 4)
//                }
//                .foregroundColor(ingredient.amount == 2 ? .secondary : .primary)
//                Spacer()
//              }
//              Divider()
//            }
//          }
          Divider()
        }
        HStack {
          Text(" ")
            .font(.title3)
            .fontWeight(.bold)
          Spacer()
          Image(systemName: "plus")
        }
        .foregroundColor(.secondary)
        Divider()
      }
    }
  }
}

struct IngredientsListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientsListView(store: .init(
          initialState: .init(viewState: .init(ingredients: Recipe.mock.ingredients)),
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

// MARK: - IngredientsListReducer
struct IngredientsListReducer: ReducerProtocol {
  struct State: Equatable {
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredientSectionNameEdited(Recipe.Ingredients.ID, String)
    case ingredientAmountEdited(Recipe.Ingredients.ID, Recipe.Ingredients.Ingredient.ID, String)
    case incrementScaleButtonTapped
    case decrementScaleButtonTapped
    case scaleIngredients
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredientSectionNameEdited(id, newName):
        state.viewState.ingredients[id: id]?.name = newName
        return .none
        
      case let .ingredientAmountEdited(ingredientSectionId, ingredientId, newAmount):
//        if let newAmount = Double(newAmount) {
//          state.viewState.ingredients[id: ingredientSectionId]?.ingredients[id: ingredientId]?.amount = newAmount
//          return .none
//        }
//        else if let newAmount = Int(newAmount) {
//          let newAmount = Double(newAmount)
//          state.viewState.ingredients[id: ingredientSectionId]?.ingredients[id: ingredientId]?.amount = newAmount
//          return .none
//        }
        guard let newAmount = Double(newAmount)
        else { return .none }
        state.viewState.ingredients[id: ingredientSectionId]?.ingredients[id: ingredientId]?.amount = newAmount
        return .none
        
      case .incrementScaleButtonTapped:
        state.viewState.scale += 1
        return .send(.scaleIngredients)

      case .decrementScaleButtonTapped:
        state.viewState.scale -= 1
        return .send(.scaleIngredients)
        
      case .scaleIngredients:
//        let old = state.viewState.ingredients
//        state.viewState.ingredients = .init(uniqueElements: state.viewState.ingredients.map { ingredients in
//          var newIngredients: Recipe.Ingredients = .init(
//            id: .init(),
//            name: ingredients.name,
//            ingredients: ingredients.ingredients
//          )
//          newIngredients.ingredients = .init(uniqueElements: newIngredients.ingredients.map { ingredient in
//            var newIngredient:  Recipe.Ingredients.Ingredient = .init(
//              id: .init(),
//              name: ingredient.name,
//              amount: ingredient.amount,
//              measure: ingredient.measure
//            )
//            newIngredient.amount *= Double(state.viewState.scale)
//            return newIngredient
//          })
//          return newIngredients
//        })
//        dump(old)
//        dump(state.viewState.ingredients)
        return .none
        
//      case .scaleIngredients:
//        let old = state.viewState.ingredients
//        state.viewState.ingredients = .init(uniqueElements: state.viewState.ingredients.map { ingredients in
//          var newIngredients: Recipe.Ingredients = .init(
//            id: .init(),
//            name: ingredients.name,
//            ingredients: ingredients.ingredients
//          )
//          newIngredients.ingredients = .init(uniqueElements: newIngredients.ingredients.map { ingredient in
//            var newIngredient:  Recipe.Ingredients.Ingredient = .init(
//              id: .init(),
//              name: ingredient.name,
//              amount: ingredient.amount,
//              measure: ingredient.measure
//            )
//            newIngredient.amount *= Double(state.viewState.scale)
//            return newIngredient
//          })
//          return newIngredients
//        })
////        dump(old)
////        dump(state.viewState.ingredients)
//        return .none
      }
    }
  }
}
extension IngredientsListReducer {
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<Recipe.Ingredients>
    var scale: Int = 1
  }
}

// MARK: - Collapsible
struct MyCollapsible<Content: View>: View {
  @State private var collapsed: Bool
  @State var label: () -> Text
  @State var content: () -> Content
  
  init(
    collapsed: Bool = true,
    @ViewBuilder label: @escaping () -> Text,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.collapsed = collapsed
    self.label = label
    self.content = content
  }
  
  
  var body: some View {
    VStack {
      Button(
        action: {
          withAnimation(.easeOut) {
            self.collapsed.toggle()
          }
        },
        label: {
          HStack {
            self.label()
            Spacer()
            Image(systemName: self.collapsed ? "chevron.down" : "chevron.up")
          }
          .padding(.bottom, 1)
          .background(Color.white.opacity(0.01))
        }
      )
      .buttonStyle(PlainButtonStyle())
      
      VStack {
        self.content()
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
      .clipped()
      .transition(.slide)
    }
  }
}

// MARK: - Collapsible
struct MyCollapsible2<Label: View, Content: View>: View {
  @State private var collapsed: Bool
  @State var label: () -> Label
  @State var content: () -> Content
  
  init(
    collapsed: Bool = true,
    @ViewBuilder label: @escaping () -> Label,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.collapsed = collapsed
    self.label = label
    self.content = content
  }
  
  
  var body: some View {
    VStack {
      HStack {
        label()
        Spacer()
        Image(systemName: self.collapsed ? "chevron.down" : "chevron.up")
          .onTapGesture {
            withAnimation(.easeOut) {
              self.collapsed.toggle()
            }
          }
      }
      .padding(.bottom, 1)
      .background(Color.white.opacity(0.01))
      
      VStack {
        self.content()
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
      .clipped()
      .transition(.slide)
    }
  }
}
