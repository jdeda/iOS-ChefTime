import SwiftUI
import ComposableArchitecture
import Tagged

struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  
  struct ViewState: Equatable {
    var ingredientsList: IngredientsListReducer.State
    let maxW = UIScreen.main.bounds.width * 0.85
    let recipe: Recipe = .mock
    
    init(_ state: RecipeReducer.State) {
      self.ingredientsList = state.ingredientsList
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ScrollView {
        Group {
          Image("recipe_09")
            .resizable()
            .scaledToFill()
            .frame(width: viewStore.maxW, height: viewStore.maxW)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding([.bottom])
        }
        
        AboutView(store: store.scope(
          state: \.about,
          action: RecipeReducer.Action.about
        ))
        
        Divider()
        
        IngredientsListView(store: store.scope(
          state: \.ingredientsList,
          action: RecipeReducer.Action.ingredientList
        ))
        
        StepsListView(store: store.scope(
          state: \.stepsList,
          action: RecipeReducer.Action.stepsList
        ))
      }
      .padding()
      .navigationTitle(viewStore.recipe.name)
    }
  }
}

struct RecipeReducer: ReducerProtocol {
  struct State: Equatable {
    var ingredientsList: IngredientsListReducer.State
    var stepsList: StepsListReducer.State
    var about: AboutReducer.State
  }
  
  enum Action: Equatable {
    case ingredientList(IngredientsListReducer.Action)
    case stepsList(StepsListReducer.Action)
    case about(AboutReducer.Action)
    
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredientList(action):
        return .none
        
      case let .stepsList(action):
        return .none
        
      case let .about(action):
        return .none
      }
    }
    Scope(state: \.ingredientsList, action: /Action.ingredientList) {
      IngredientsListReducer()
    }
    Scope(state: \.stepsList, action: /Action.stepsList) {
      StepsListReducer()
    }
    Scope(state: \.about, action: /Action.about) {
      AboutReducer()
    }
  }
}

struct RecipeView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      RecipeView(store: .init(
        initialState: RecipeReducer.State(
          ingredientsList: .init(recipe: .mock, isExpanded: true),
          stepsList: .init(recipe: .mock, isExpanded: true),
          about: .init(isExpanded: true, description: Recipe.mock.about)
        ),
        reducer: RecipeReducer.init,
        withDependencies: { _ in
          // TODO:
        }
      ))
        .scrollContentBackground(.hidden)
        .background {
          Image(systemName: "recipe_05")
            .resizable()
            .scaledToFill()
            .blur(radius: 10)
            .ignoresSafeArea()
        }
    }
  }
}
