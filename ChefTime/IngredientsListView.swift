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
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      // Ingredients.
      MyCollapsible(collapsed: false) {
        Text("Ingredients")
          .font(.title)
          .fontWeight(.bold)
      } content: {
        ForEach(viewStore.ingredients) { ingredients in
          MyCollapsible2(collapsed: true) {
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
            ForEach(ingredients.ingredients, id: \.name) { ingredient in
              HStack {
                HStack(alignment: .top) {
                  Image(systemName: ingredient.amount == 2 ? "checkmark.square" : "square")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .padding([.top], 4)

                  Text("\(Int(ingredient.amount)) \(ingredient.measure) \(ingredient.name)")
                    .fontWeight(.medium)
                }
                .foregroundColor(ingredient.amount == 2 ? .secondary : .primary)
                Spacer()
              }
            }
          }
          Divider()
        }
//        HStack {
//          Text(" ")
//            .font(.title3)
//            .fontWeight(.bold)
//          Spacer()
//          Image(systemName: "plus")
//        }
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
    
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredientSectionNameEdited(id, newName):
        state.viewState.ingredients[id: id]?.name = newName
        return .none
        
      }
    }
  }
}
extension IngredientsListReducer {
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<Recipe.Ingredients>
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
