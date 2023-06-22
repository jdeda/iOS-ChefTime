import SwiftUI
import ComposableArchitecture
import Tagged


// TODO: Make sure disclosure group styles are consistent
/// How do we model previews...
/// Recipe
///   - PhotoFeature
///   - AboutPreview
///   - IngredientsPreview
///   - StepsPreview
///
/// When we tap the about preview in a specific location, we should navigate to a
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
    var ingredientsList: IngredientsListPreviewReducer.State
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
        .padding([.bottom])
        
        AboutPreviewListView(store: store.scope(
          state: \.aboutList,
          action: RecipeReducer.Action.aboutList
        ))
                
        IngredientListPreview(store: store.scope(
          state: \.ingredientsList,
          action: RecipeReducer.Action.ingredientList
        ))
                
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
    var photos: PhotosReducer.State
    var aboutList: AboutPreviewListReducer.State
    var ingredientsList: IngredientsListPreviewReducer.State
    var stepsList: StepsListReducer.State
    
    init(recipe: Recipe) {
      self.recipe = recipe
      self.photos = .init(recipe: recipe)
      self.aboutList = .init(recipe: recipe, isExpanded: true, childrenIsExpanded: true)
      self.ingredientsList = .init(recipe: recipe, isExpanded: true)
      self.stepsList = .init(recipe: recipe, isExpanded: true, childrenIsExpanded: true)
    }
  }
  
  enum Action: Equatable {
    case photos(PhotosReducer.Action)
    case aboutList(AboutPreviewListReducer.Action)
    case ingredientList(IngredientsListPreviewReducer.Action)
    case stepsList(StepsListReducer.Action)
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
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
    Scope(state: \.aboutList, action: /Action.aboutList) {
      AboutPreviewListReducer()
    }
    Scope(state: \.ingredientsList, action: /Action.ingredientList) {
      IngredientsListPreviewReducer()
    }
    Scope(state: \.stepsList, action: /Action.stepsList) {
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
