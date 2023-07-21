import SwiftUI
import ComposableArchitecture
import Tagged

// TODO: If deleting, maybe nil focus, keyboard animation gets ugly
// TODO: sometimes screen moves very weird on inserts
// TODO: ingredient .next/return sometimes doesnt focus to new element
// TODO: rename model and feature names to be more consistent

// TODO: Make sure disclosure group styles are consistent
struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        ScrollView {
          VStack {
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
              // TODO: This must be the same size as the photos view
              // or expansion will look werd
            }
          }
          .animation(.default, value: viewStore.isHidingImages)
          
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
            action: RecipeReducer.Action.ingredients
          ))
          .padding([.horizontal])
          
          if viewStore.ingredients.isExpanded && viewStore.ingredients.ingredients.last?.isExpanded == false {
            EmptyView()
          }
          else {
            if !viewStore.ingredients.isExpanded || viewStore.ingredients.ingredients.isEmpty ||
                viewStore.ingredients.ingredients.last?.ingredients.isEmpty ?? false
            {
              Divider()
                .padding([.horizontal])
                .padding([.top], 5)
            }
          }
          
          StepListView(store: store.scope(
            state: \.steps,
            action: RecipeReducer.Action.steps
          ))
          .padding([.horizontal])

          
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
    var steps: StepListReducer.State
    var isHidingImages: Bool
    
    init(recipe: Recipe) {
      @Dependency(\.uuid) var uuid
      self.recipe = recipe
      self.photos = .init(
        photos: recipe.imageData,
        selection: recipe.imageData.first?.id
      )
      self.about = .init(
        aboutSections: .init(uniqueElements: recipe.aboutSections.map({ section in
            .init(
              id: .init(rawValue: uuid()),
              aboutSection: section,
              isExpanded: true
            )
        })),
        isExpanded: true,
        focusedField: nil
      )
      self.ingredients = .init(
        ingredients: .init(uniqueElements: recipe.ingredientSections.map({ section in
            .init(
              id: .init(rawValue: uuid()),
              name: section.name,
              ingredients: .init(uniqueElements: section.ingredients.map({ ingredient in
                  .init(
                    id: .init(),
                    focusedField: nil,
                    ingredient: ingredient,
                    emptyIngredientAmountString: false
                  )
              })),
              isExpanded: true,
              focusedField: nil
            )
        })),
        isExpanded: true,
        scale: 1.0,
        focusedField: nil
      )
      
      self.steps = .init(
        stepSections: .init(uniqueElements: recipe.steps.map({ section in
            .init(
              id: .init(),
              name: section.name,
              steps: .init(uniqueElements: section.steps.map({ step in
                  .init(id: .init(), step: step, focusedField: nil)
              })),
              isExpanded: true,
              focusedField: nil
            )
        })),
        isExpanded: true,
        focusedField: nil
      )
      
      self.isHidingImages = false
    }
  }
  
  enum Action: Equatable {
    case photos(PhotosReducer.Action)
    case about(AboutListReducer.Action)
    case ingredients(IngredientsListReducer.Action)
    case steps(StepListReducer.Action)
    case recipeNameEdited(String)
    case toggleHideImages
    case setExpansionButtonTapped(Bool)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .photos, .about, .ingredients, .steps:
        return .none
        
      case let .recipeNameEdited(newName):
        state.recipe.name = newName
        return .none
        
      case .toggleHideImages:
        state.isHidingImages.toggle()
        return .none
        
      case let .setExpansionButtonTapped(isExpanded):
        // TODO: May need to worry about focus state

        // Collapse all about sections
        state.about.isExpanded = isExpanded
        state.about.aboutSections.ids.forEach {
          state.about.aboutSections[id: $0]?.isExpanded = isExpanded
        }
        
        // Collapse all ingredient sections
        state.ingredients.isExpanded = isExpanded
        state.ingredients.ingredients.ids.forEach {
          state.ingredients.ingredients[id: $0]?.isExpanded = isExpanded
        }
        
        // Collapse all step sections
        state.steps.isExpanded = isExpanded
        state.steps.stepSections.ids.forEach {
          state.steps.stepSections[id: $0]?.isExpanded = isExpanded
        }
        return .none
      }
    }
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
    Scope(state: \.about, action: /Action.about) {
      AboutListReducer()
    }
    Scope(state: \.ingredients, action: /Action.ingredients) {
      IngredientsListReducer()
    }
    Scope(state: \.steps, action: /Action.steps) {
      StepListReducer()
    }
  }
}

struct RecipeView_Previews: PreviewProvider {
  static var previews: some View {
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
}
