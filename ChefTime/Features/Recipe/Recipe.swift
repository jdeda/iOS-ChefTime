import SwiftUI
import ComposableArchitecture
import Tagged

// MARK: - Recipe Feature UI Concerning but Acceptable Bugs
/// These bugs are concerning, but do not jepordize the quality of the app signicantly.
/// Most of the bugs are usually ignorable and may be internal SwiftUI bugs.
/// 1. Keyboard displays auto-fill words but not for all keyboards
/// 2. Upon inserting sections or elements, screen moves a bit unpleasantly, and or may not
///   be in perfect position (i.e. it could lower a bit more to really show the textfield). This
///   may be because of padding issues

// MARK: - Recipe Feature Animation Bugs
/// - Step image deletion final photo transition is fugly
/// - Photos delete final photo transition to base is kinda weird
/// - Photos sometimes delete just doesnt work and it gets stuck
/// - About/Ingredient/Step feature context menu doesn't transition off, you get a big black hole
/// - About/Ingredient/Step feature deletion is ugly, it lingers, ingredient kinda similar
/// - TextFields get laggy AF <----- ----- ----- ----- ----- ----- ----- -----  BIG PROBLEM
/// - Sometimes textfield highlight when focused just doesn't appear...
/// - Spamming the hide images then spamming expand collapse combinations glitch and get the images stuck hidden

// MARK: - Recipe Usability Issues
/// 1. Tapping collapse button near other features i.e. ingredient / step can be crammed and its ease to mess up where you tap
/// 2. Sometimes when you collapse the delay is a bit annoying because you may tap again because you think it should
/// instantly tap but it doesnt, and the button isn't big enough neither is the impact area, the collapse animation should be much faster
/// Apple already designed it very well
/// 3. Ingredients still double insert  (sometimes) (refactor all debounces)
/// 4. Focus state still breaks (sometimes)


// TODO: ingredient .next/return sometimes doesnt focus to new element
// TODO: Consider lazy rendering and  limit observation for performance
// TODO: Refactor SectionedListView into resuable TCA feature...this would delete an insane amount of duplicate code.

struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        ScrollView {
          ZStack {
            PhotosView(store: store.scope(state: \.photos, action: RecipeReducer.Action.photos))
            .opacity(!viewStore.isHidingImages ? 1.0 : 0.0)
            .frame(
              width: !viewStore.isHidingImages ? maxScreenWidth.maxWidth : 0,
              height: !viewStore.isHidingImages ? maxScreenWidth.maxWidth : 0
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
            .padding([.bottom, .top], !viewStore.isHidingImages ? 10 : 0 )
            
            // This allows the expansion toggle animation to work properly.
            Color.clear
              .contentShape(Rectangle())
              .frame(width: maxScreenWidth.maxWidth, height: 0)
              .clipShape(RoundedRectangle(cornerRadius: 15))
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
              .padding([.bottom, .top], !viewStore.isHidingImages ? 10 : 0 )
          }
          
          AboutListView(store: store.scope(
            state: \.about,
            action: RecipeReducer.Action.about
          ))
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          
          if !viewStore.about.isExpanded {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }

          IngredientListView(store: store.scope(
            state: \.ingredients,
            action: RecipeReducer.Action.ingredients
          ))
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)

          if !viewStore.ingredients.isExpanded {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }

          StepListView(store: store.scope(
            state: \.steps,
            action: RecipeReducer.Action.steps
          ))
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          
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

struct RecipeReducer: Reducer {
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
        ingredientSections: .init(uniqueElements: recipe.ingredientSections.map({ section in
            .init(
              id: .init(rawValue: uuid()),
              name: section.name,
              ingredients: .init(uniqueElements: section.ingredients.map({ ingredient in
                  .init(
                    id: .init(),
                    ingredient: ingredient,
                    ingredientAmountString: String(ingredient.amount),
                    focusedField: nil
                  )
              })),
              isExpanded: true,
              focusedField: nil
            )
        })),
        isExpanded: true,
        focusedField: nil
      )
      
      self.steps = .init(
        stepSections: .init(uniqueElements: recipe.stepSections.map({ section in
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
  
  var body: some ReducerOf<Self> {
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
        state.ingredients.ingredientSections.ids.forEach {
          state.ingredients.ingredientSections[id: $0]?.isExpanded = isExpanded
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

// MARK: - Environment ScreenWidth
/// Represents maximum screen width and offsets.
struct MaxScreenWidth: EnvironmentKey {
  public static let defaultValue = Self.init(maxWidthPercentage: 0.9)
  
  /// Represents the width of the device screen.
  static let width: CGFloat = UIScreen.main.bounds.width
  
  /// Represents the maximum width percentage of the device screen.
  let maxWidthPercentage: Double
  
  /// Represents the maximum computed width of the device screen.
  var maxWidth: CGFloat {
    UIScreen.main.bounds.width * maxWidthPercentage
  }
  
  /// Represents the horizontal space between the device screen width
  /// and computed maximum computed width of the device screen
  var maxWidthHorizontalOffset: CGFloat {
    Self.width * (1.0 - maxWidthPercentage)
  }
}
extension EnvironmentValues {
  var maxScreenWidth: MaxScreenWidth {
    get { self[MaxScreenWidth.self] }
    set { self[MaxScreenWidth.self] = newValue }
  }
}

// MARK: - Previews
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
