import SwiftUI
import ComposableArchitecture

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
          MyCollapsible(collapsed: true) {
            Text(ingredients.name)
              .font(.title3)
              .fontWeight(.bold)
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
    
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      }
    }
  }
}
extension IngredientsListReducer {
  struct ViewState: Equatable {
    var ingredients: IdentifiedArrayOf<Recipe.Ingredients>
  }
}

// MARK: - IngredientsView
struct IngredientsView: View {
  let ingredients: Recipe.Ingredients
  
  init(ingredients: Recipe.Ingredients = Recipe.mock.ingredients.first!) {
    self.ingredients = ingredients
  }
  
  var body: some View {
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
