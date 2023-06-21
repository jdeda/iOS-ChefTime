import SwiftUI
import ComposableArchitecture
import Tagged

struct DataImage2View: View {
  let imageData: Data?
  let maxW = UIScreen.main.bounds.width * 0.85
  
  var body: some View {
    if let imageData = imageData,
       let image = dataToImage(imageData) {
      image
        .resizable()
        .scaledToFill()
        .frame(width: maxW, height: maxW)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding([.bottom])
    }
    else {
      Image(systemName: "photo")
        .resizable()
        .scaledToFill()
        .frame(width: maxW, height: maxW)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding([.bottom])
    }
  }
}

struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  
  struct ViewState: Equatable {
    var ingredientsList: IngredientsListReducer.State
    let maxW = UIScreen.main.bounds.width * 0.85
    let recipe: Recipe = .longMock
    
    init(_ state: RecipeReducer.State) {
      self.ingredientsList = state.ingredientsList
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ScrollView {
        
        PhotosView(store: store.scope(
          state: \.photos,
          action: RecipeReducer.Action.photos
        ))
        
        AboutListView(store: store.scope(
          state: \.aboutList,
          action: RecipeReducer.Action.aboutList
        ))
        
        Divider()
        
        IngredientsListView(store: store.scope(
          state: \.ingredientsList,
          action: RecipeReducer.Action.ingredientList
        ))
        
        Divider()
        
        StepsListView(store: store.scope(
          state: \.stepsList,
          action: RecipeReducer.Action.stepsList
        ))
      }
      .padding()
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
    var aboutList: AboutListReducer.State
    var photos: PhotosReducer.State
    
    init(recipe: Recipe) {
      self.recipe = recipe
      self.ingredientsList = .init(recipe: recipe, isExpanded: false)
      self.stepsList = .init(recipe: recipe, isExpanded: false)
      self.aboutList = .init(recipe: recipe, isExpanded: false)
      self.photos = .init(recipe: recipe)
    }
  }
  
  enum Action: Equatable {
    case ingredientList(IngredientsListReducer.Action)
    case stepsList(StepsListReducer.Action)
    case aboutList(AboutListReducer.Action)
    case photos(PhotosReducer.Action)
    case recipeNameEdited(String)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .ingredientList(action):
        return .none
        
      case let .stepsList(action):
        return .none
        
      case let .aboutList(action):
        return .none
        
      case let .photos(action):
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
    Scope(state: \.aboutList, action: /Action.aboutList) {
      AboutListReducer()
    }
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
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
