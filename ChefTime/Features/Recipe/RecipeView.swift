import SwiftUI
import ComposableArchitecture
import Tagged

/// TODO: Make sure disclosure group styles are consistent
struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  
  struct ViewState: Equatable {
    var ingredientsList: IngredientsListPreviewReducer.State
    let maxW = UIScreen.main.bounds.width * 0.85
    let recipe: Recipe = .longMock
    
    init(_ state: RecipeReducer.State) {
      self.ingredientsList = state.ingredients
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ScrollView {
        PhotosView(store: store.scope(
          state: \.photos,
          action: RecipeReducer.Action.photos
        ))
        .padding([.horizontal])
        .padding([.bottom])
        
        AboutPreviewListView(store: store.scope(
          state: \.about,
          action: RecipeReducer.Action.about
        ))
        .padding([.horizontal])
        
        IngredientListPreview(store: store.scope(
          state: \.ingredients,
          action: RecipeReducer.Action.list
        ))
        .padding([.horizontal])
        
        StepsListView(store: store.scope(
          state: \.steps,
          action: RecipeReducer.Action.steps
        ))
        .padding([.horizontal])
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
    var photos: PhotosReducer.State
    var about: AboutPreviewListReducer.State
    var ingredients: IngredientsListPreviewReducer.State
    var steps: StepsListReducer.State
    
    init(recipe: Recipe) {
      self.recipe = recipe
      self.photos = .init(recipe: recipe)
      self.about = .init(recipe: recipe, isExpanded: true, childrenIsExpanded: true)
      self.ingredients = .init(recipe: recipe, isExpanded: true, childrenIsExpanded: true)
      self.steps = .init(recipe: recipe, isExpanded: false, childrenIsExpanded: false)
    }
  }
  
  enum Action: Equatable {
    case photos(PhotosReducer.Action)
    case about(AboutPreviewListReducer.Action)
    case list(IngredientsListPreviewReducer.Action)
    case steps(StepsListReducer.Action)
    case recipeNameEdited(String)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .list(action):
        return .none
        
      case let .steps(action):
        return .none
        
      case let .about(action):
        return .none
        
      case let .photos(action):
        return .none
        
      case let .recipeNameEdited(newName):
        state.recipe.name = newName
        return .none
      }
    }
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
    Scope(state: \.about, action: /Action.about) {
      AboutPreviewListReducer()
    }
    Scope(state: \.ingredients, action: /Action.list) {
      IngredientsListPreviewReducer()
    }
    Scope(state: \.steps, action: /Action.steps) {
      StepsListReducer()
    }
  }
}

struct RecipeView_Previews: PreviewProvider {
  static var previews: some View {
    // Long
    NavigationStack {
      RecipeView(store: .init(
        initialState: RecipeReducer.State(
          recipe: .longMock
        ),
        reducer: RecipeReducer.init,
        withDependencies: { _ in
          // TODO:
        }
      ))
    }
    // Short
    NavigationStack {
      RecipeView(store: .init(
        initialState: RecipeReducer.State(
          recipe: .shortMock
        ),
        reducer: RecipeReducer.init,
        withDependencies: { _ in
          // TODO:
        }
      ))
    }
    // Empty
    NavigationStack {
      RecipeView(store: .init(
        initialState: RecipeReducer.State(
          recipe: .empty
        ),
        reducer: RecipeReducer.init,
        withDependencies: { _ in
          // TODO:
        }
      ))
    }
  }
}
