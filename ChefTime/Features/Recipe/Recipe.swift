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

// MARK: - Possible Improvements
/// 1. Consider lazy rendering and  limit observation for performance
/// 2. Refactor SectionedListView into resuable TCA feature...this would delete an insane amount of duplicate code.

// MARK: - Recipe Feature Animation Bugs
/// - Sometimes textfield highlight when focused just doesn't appear...
/// - Spamming the hide images then spamming expand collapse combinations glitch and get the images stuck hidden

// MARK: - Haunting Bugs
/// 1. Ingredients still double insert  (sometimes) (refactor all debounces)
/// 2. Focus state still breaks (sometimes)

// MARK: - Haunting DisclosureGroup Animation Bugs:
/// 1. Context menu doesn't transition off, you get a big black hole
/// 2. Deletion is ugly, the elements that are deleted linger and do not transition properly
/// 3. Add is ugly, the context menus linger and do not transition properly
/// I think just any context menu transition is just completely broken.
/// The TextField is the culprit of breaking context menus but I have found a way to fix it, you cannot
/// just go set the UIPreviewTarget.background for an entire view root, you have to specifically create an entire new deleagte
/// and handle all of the bullshit and nuances literally JUST to set the stupid ass background to clear.

// TODO: Move all the autcorrection stuff into a dependency and possibly write a modifier that you can apply to all
// your textfields to have, or maybe if really based, it just does it compeltely for you and you don't even have to
// append that to any of your textfields

struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  @Environment(\.maxScreenWidth) private var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        
        // PhotosView
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
        
        // AboutListView
        IfLetStore(store.scope(
          state: \.about,
          action: RecipeReducer.Action.about
        )) {
          AboutListView(store: $0)
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          
          if !(viewStore.about?.isExpanded ?? false) {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }
        }
        
        // IngredientListView
        IfLetStore(store.scope(
          state: \.ingredients,
          action: RecipeReducer.Action.ingredients
        )) {
          IngredientListView(store: $0)
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          
          if !(viewStore.ingredients?.isExpanded ?? false) {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }
        }
        
        // StepListView
        IfLetStore(store.scope(
          state: \.steps,
          action: RecipeReducer.Action.steps
        )) {
          StepListView(store: $0)
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          
          if !(viewStore.steps?.isExpanded ?? false) {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }
        }
        
        Spacer()
      }
      .alert(store: store.scope(state: \.$alert, action: RecipeReducer.Action.alert))
      .navigationTitle(viewStore.binding(
        get:  { !$0.name.isEmpty ? $0.name : "Untitled Recipe" },
        send: { .recipeNameEdited($0) }
      ))
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Menu {
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
              Label("Edit Visibility", systemImage: "eyeglasses")
            }

            Menu {
              Button {
                viewStore.send(.editSectionButtonTapped(.about, viewStore.about == nil ? .add : .delete), animation: .default)
              } label: {
                Label(viewStore.about == nil ? "Add About" : "Delete About", systemImage: "text.alignleft")
              }
              Button {
                viewStore.send(.editSectionButtonTapped(.ingredients, viewStore.ingredients == nil ? .add : .delete), animation: .default)
              } label: {
                Label(viewStore.ingredients == nil ? "Add Ingredients" : "Delete Ingredients", systemImage: "checklist")
              }
              Button {
                viewStore.send(.editSectionButtonTapped(.steps, viewStore.steps == nil ? .add : .delete), animation: .default)
              } label: {
                Label(viewStore.steps == nil ? "Add Steps" : "Delete Steps", systemImage: "list.number")
              }
            } label: {
              Label("Edit Sections", systemImage: "line.3.horizontal")
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

struct RecipeReducer: Reducer {
  struct State: Equatable {
    var name: String
    var photos: PhotosReducer.State
    var about: AboutListReducer.State?
    var ingredients: IngredientsListReducer.State?
    var steps: StepListReducer.State?
    var isHidingImages: Bool
    @PresentationState var alert: AlertState<AlertAction>?
    
    init(recipe: Recipe) {
      @Dependency(\.uuid) var uuid
      self.name = recipe.name
      
      self.photos = .init(
        photos: recipe.imageData,
        disableContextMenu: false,
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
    case editSectionButtonTapped(Section, SectionEditAction)
    case alert(PresentationAction<AlertAction>)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .photos, .about, .ingredients, .steps:
        return .none
        
      case let .recipeNameEdited(newName):
        state.name = newName
        return .none
        
      case .toggleHideImages:
        state.isHidingImages.toggle()
        return .none
        
      case let .setExpansionButtonTapped(isExpanded):
        // TODO: May need to worry about focus state
        
        // Collapse all about sections
        state.about?.isExpanded = isExpanded
        state.about?.aboutSections.ids.forEach {
          state.about?.aboutSections[id: $0]?.isExpanded = isExpanded
        }
        
        // Collapse all ingredient sections
        state.ingredients?.isExpanded = isExpanded
        state.ingredients?.ingredientSections.ids.forEach {
          state.ingredients?.ingredientSections[id: $0]?.isExpanded = isExpanded
        }
        
        // Collapse all step sections
        state.steps?.isExpanded = isExpanded
        state.steps?.stepSections.ids.forEach {
          state.steps?.stepSections[id: $0]?.isExpanded = isExpanded
        }
        return .none
        
      case let .editSectionButtonTapped(section, action):
        switch action {
        case .delete:
          switch section {
          case .about: state.alert = .deleteAbout
          case .ingredients: state.alert = .deleteIngredients
          case .steps: state.alert = .deleteSteps
          }
          return .none
          
        case .add:
          switch section {
          case .about: state.about = .init()
          case .ingredients: state.ingredients = .init()
          case .steps: state.steps = .init()
          }
          return .none
        }
        
      case let .alert(.presented(.confirmDeleteSectionButtonTapped(section))):
        switch section {
        case .about: state.about = nil
        case .ingredients: state.ingredients = nil
        case .steps: state.steps = nil
        }
        state.alert = nil
        return .none

      case .alert(.dismiss):
        state.alert = nil
        return .none

      case .alert, .delegate:
        return .none
      }
    }
    .onChange(of: { $0 } , { _, newValue in
      Reduce { _, _ in
          .send(.delegate(.recipeUpdated(newValue)))
      }
    })
    .ifLet(\.about, action: /Action.about) {
      AboutListReducer()
    }
    .ifLet(\.ingredients, action: /Action.ingredients) {
      IngredientsListReducer()
    }
    .ifLet(\.steps, action: /Action.steps) {
      StepListReducer()
    }
    
    Scope(state: \.photos, action: /Action.photos) {
      PhotosReducer()
    }
  }
}

// MARK: - DelegateAction
extension RecipeReducer {
  enum DelegateAction: Equatable {
    case recipeUpdated(RecipeReducer.State)
  }
}


// MARK: - AlertAction
extension RecipeReducer {
  enum AlertAction: Equatable {
    case confirmDeleteSectionButtonTapped(Section)
  }
}


// MARK: - AlertState
extension AlertState where Action == RecipeReducer.AlertAction {
  static let deleteAbout = Self(
    title: {
      TextState("Delete About")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSectionButtonTapped(.about)){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteIngredients = Self(
    title: {
      TextState("Delete Ingredients")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSectionButtonTapped(.ingredients)){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteSteps = Self(
    title: {
      TextState("Delete Steps")
    },
    actions: {
      ButtonState(role: .destructive, action: .confirmDeleteSectionButtonTapped(.steps)){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
}


// MARK: - Section Helper
extension RecipeReducer {
  enum Section: Equatable {
    case about
    case ingredients
    case steps
  }
  
  enum SectionEditAction: Equatable {
    case add
    case delete
  }
}

// MARK: - Previews
struct RecipeView_Previews: PreviewProvider {
  static var previews: some View {
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
  }
}
