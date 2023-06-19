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
          Group {
//            Image("recipe_09")
//              .resizable()
//              .scaledToFill()
//              .frame(width: viewStore.maxW, height: viewStore.maxW)
//              .clipShape(RoundedRectangle(cornerRadius: 15))
//              .padding([.bottom])
            
            if let imageData = viewStore.recipe.imageData, let image = dataToImage(imageData) {
              image
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            else {
              Image(systemName: "square")
              EmptyView()
            }
          }
          
//          AboutView(store: store.scope(
//            state: \.about,
//            action: RecipeReducer.Action.about
//          ))
//
//          Divider()
//
//          IngredientsListView(store: store.scope(
//            state: \.ingredientsList,
//            action: RecipeReducer.Action.ingredientList
//          ))
//
//          Divider()
//
//          StepsListView(store: store.scope(
//            state: \.stepsList,
//            action: RecipeReducer.Action.stepsList
//          ))
        }
        .padding()
      }
      .navigationTitle(viewStore.binding(
        get:  \.recipe.name,
        send: { .recipeNameEdited($0) }
      ))
    }
  }
}

struct RecipeReducer: ReducerProtocol {
  struct State: Equatable {
    var recipe: Recipe
    var ingredientsList: IngredientsListReducer.State
    var stepsList: StepsListReducer.State
    var about: AboutReducer.State
  }
  
  enum Action: Equatable {
    case ingredientList(IngredientsListReducer.Action)
    case stepsList(StepsListReducer.Action)
    case about(AboutReducer.Action)
    case recipeNameEdited(String)
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
      case let .recipeNameEdited(newName):
        state.recipe.name = newName
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
          recipe: .mock,
          ingredientsList: .init(recipe: .mock, isExpanded: true),
          stepsList: .init(recipe: .mock, isExpanded: true),
          about: .init(isExpanded: true, description: Recipe.mock.about)
        ),
        reducer: RecipeReducer.init,
        withDependencies: { _ in
          // TODO:
        }
      ))
    }
  }
}
