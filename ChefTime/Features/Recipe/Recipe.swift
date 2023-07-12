import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: If deleting, maybe nil focus, keyboard animation gets ugly
// TODO: sometimes screen moves very weird on inserts
// TODO: ingredient .next/return sometimes doesnt focus to new element

// TODO: Make sure disclosure group styles are consistent
struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        ScrollView {
          if !viewStore.isHidingImages {
            PhotosView(store: store.scope(
              state: \.photos,
              action: RecipeReducer.Action.photos
            ))
            .padding([.horizontal])
            .padding([.bottom, .top])
          }
          else {
            Rectangle()
              .fill(.clear)
              .frame(height: 5)
          }

          // TODO: If tapped done on section with empty name and ingredients delete it
          AboutListView(store: store.scope(
            state: \.about,
            action: RecipeReducer.Action.about
          ))
          .padding([.horizontal])
          
          if viewStore.about.isExpanded && viewStore.about.aboutSections.last?.isExpanded == false {
            EmptyView()
          }
          else {
            Divider()
              .padding([.horizontal])
              .padding([.top], 5)
          }

          // TODO: if empty or if last section has no ingredients, put a divider
          IngredientListView(store: store.scope(
            state: \.ingredients,
            action: RecipeReducer.Action.list
          ))
          .padding([.horizontal])
          
          if viewStore.ingredients.isExpanded && viewStore.ingredients.ingredients.last?.isExpanded == false {
            EmptyView()
          }
          else {
            if viewStore.ingredients.ingredients.isEmpty ||
                viewStore.ingredients.ingredients.last?.ingredients.isEmpty ?? false
            {
              Divider()
                .padding([.horizontal])
                .padding([.top], 5)
            }
          }

          
          Spacer()
        }
        .navigationTitle(viewStore.binding(
          get:  { !$0.recipe.name.isEmpty ? $0.recipe.name : "Untitled Recipe" },
          send: { .recipeNameEdited($0) }
        ))
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            Menu {
              Button {
                viewStore.send(.setExpansionButtonTapped(true), animation: .default)
              } label: {
                Label("Expand All", systemImage: "arrow.up.backward.and.arrow.down.forward")
              }
              Button {
                viewStore.send(.setExpansionButtonTapped(false), animation: .default)
              } label: {
                Label("Collapse All", systemImage: "arrow.down.forward.and.arrow.up.backward")
              }
              Button {
                viewStore.send(.toggleHideImages, animation: .default)
              } label: {
                Label(viewStore.isHidingImages ? "Unhide Images" : "Hide Images", systemImage: "photo.stack")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
            .foregroundColor(.primary)
          }
        }
      }
    }
  }
}

struct RecipeReducer: ReducerProtocol {
  struct State: Equatable {
    var recipe: Recipe
    var photos: PhotosReducer.State
    var about: AboutListReducer.State
    var ingredients: IngredientsListReducer.State
    var isHidingImages: Bool
    
    @PresentationState var destination: DestinationReducer.State?
    
    init(recipe: Recipe, destination: DestinationReducer.State? = nil) {
      @Dependency(\.uuid) var uuid
      self.recipe = recipe
      self.photos = .init(recipe: recipe)
      self.about = .init(recipe: recipe, isExpanded: true, childrenIsExpanded: true)
//      self.ingredients = .init(recipe: recipe, isExpanded: true, childrenIsExpanded: true)
      self.ingredients = .init(
        ingredients: .init(uniqueElements: recipe.ingredientSections.map({ section in
            .init(
              id: .init(rawValue: uuid()),
              name: section.name,
              ingredients: .init(uniqueElements: section.ingredients.map({ ingredient in
                  .init(id: .init(), focusedField: nil, ingredient: ingredient, emptyIngredientAmountString: false)
              })),
              isExpanded: true,
              focusedField: nil
            )
        })),
        isExpanded: true,
        scale: 1.0,
        focusedField: nil
      )
      self.isHidingImages = false
      self.destination = destination
    }
  }
  
  enum Action: Equatable {
    case photos(PhotosReducer.Action)
    case about(AboutListReducer.Action)
    case list(IngredientsListReducer.Action)
    case recipeNameEdited(String)
    case toggleHideImages
    case setExpansionButtonTapped(Bool)
    case destination(PresentationAction<DestinationReducer.Action>)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case let .list(action):
        switch action {
        case .delegate(.sectionNavigationAreaTapped):
          state.destination = .ingredients(IngredientsListReducer.State.init(
            recipe: state.recipe,
            isExpanded: true,
            childrenIsExpanded: true
          ))
          return .none
        default: return .none
        }
        
      case let .about(action):
        return .none
        
      case let .photos(action):
        return .none
        
      case let .recipeNameEdited(newName):
        state.recipe.name = newName
        return .none
        
      case let .destination(action):
        return .none
        
      case .toggleHideImages:
        state.isHidingImages.toggle()
        return .none
    
      case let .setExpansionButtonTapped(expand):
        state.about.isExpanded = expand
        state.about.aboutSections.ids.forEach {
          state.about.aboutSections[id: $0]?.isExpanded = expand
        }
        // TODO: May need to worry about focus state
        
        state.ingredients.isExpanded = expand
        state.ingredients.ingredients.ids.forEach {
          state.ingredients.ingredients[id: $0]?.isExpanded = expand
        }
        return .none
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      DestinationReducer()
    }
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
    Scope(state: \.about, action: /Action.about) {
      AboutListReducer()
    }
    Scope(state: \.ingredients, action: /Action.list) {
      IngredientsListReducer()
    }
  }
}

extension RecipeReducer {
  struct DestinationReducer: ReducerProtocol {
    enum State: Equatable {
      case ingredients(IngredientsListReducer.State)
    }
    
    enum Action: Equatable {
      case ingredients(IngredientsListReducer.Action)
    }
    
    var body: some ReducerProtocolOf<Self> {
      Scope(state: /State.ingredients, action: /Action.ingredients) {
        IngredientsListReducer()
      }
    }
  }
}

struct RecipeView_Previews: PreviewProvider {
  static var previews: some View {
    // Long
//    RecipeView(store: .init(
//      initialState: RecipeReducer.State(
//        recipe: .longMock
//      ),
//      reducer: RecipeReducer.init,
//      withDependencies: { _ in
//        // TODO:
//      }
//    ))
//    // Short
//    RecipeView(store: .init(
//      initialState: RecipeReducer.State(
//        recipe: .shortMock
//      ),
//      reducer: RecipeReducer.init,
//      withDependencies: { _ in
//        // TODO:
//      }
//    ))
    // Empty
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
