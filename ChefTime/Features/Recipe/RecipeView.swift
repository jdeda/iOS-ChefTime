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
        AboutListView(store: store.scope(
          state: \.about,
          action: RecipeReducer.Action.about
        ))
        .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
        
        if !viewStore.about.isExpanded {
          Divider()
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
        }
        
        // IngredientListView
        IngredientListView(store: store.scope(
          state: \.ingredients,
          action: RecipeReducer.Action.ingredients
        ))
        .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
        
        if !viewStore.ingredients.isExpanded {
          Divider()
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
        }
        
        // StepListView
        StepListView(store: store.scope(
          state: \.steps,
          action: RecipeReducer.Action.steps
        ))
        .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
        
        if !viewStore.steps.isExpanded {
          Divider()
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
        }
        
        Spacer()
      }
      .alert(store: store.scope(state: \.$alert, action: RecipeReducer.Action.alert))
      .navigationTitle(viewStore.$navigationTitle)
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
