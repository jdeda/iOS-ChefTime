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
/// 1. Consider lazy rendering and limit observation for performance
/// 2. Refactor SectionedListView into resuable TCA feature...this would delete an insane amount of duplicate code.
/// 3. Refactor special TextFields into reusable TCA feature...this would delete a lot
/// of convoluted duplicate code
/// 4. NavigationTitle sucks, editing it is bizzare with that menu, not intuitive, and it doesn't
///   fit enough lines (should be infinite or max 2-3)
///  5. Make textfield autocorrect/cap dependency/global value

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


// TODO: Make sure the dividers between lists appears as intended

struct RecipeView: View {
  let store: StoreOf<RecipeReducer>
  @Environment(\.maxScreenWidth) private var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        
        // Unfournately, navigation title does not work here
        // because it doesn't support multiple lines in
        // the way we want it to behave.
        TextField("Untitled Recipe", text: viewStore.$navigationTitle, axis: .vertical)
          .multilineTextAlignment(.leading)
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .textNavigationTitleStyle()
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          .padding([.bottom], !viewStore.isHidingImages ? 10 : 0 )

        // PhotosView
        let isHiding: Bool = viewStore.isHidingImages || viewStore.photos.photos.isEmpty
        PhotosView(store: store.scope(state: \.photos, action: { .photos($0) }))
          .opacity(!isHiding ? 1.0 : 0.0)
          .frame(
            width: !isHiding ? maxScreenWidth.maxWidth : 0,
            height: !isHiding ? maxScreenWidth.maxWidth : 0
          )
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          .padding([.bottom], !isHiding ? 10 : 0 )

//        let isHidingPhotosView: Bool = {
//          if isHidingStepImages { return true }
//          else if viewStore.photos.photos.isEmpty { return true }
//          else {
//            return !(viewStore.photos.photoEditStatus == .addWhenEmpty && viewStore.photos.photoEditInFlight)
//          }
//        }()
//        PhotosView(store: store.scope(state: \.photos, action: { .photos($0) }))
//        .frame(height: isHidingPhotosView ? 0 : maxScreenWidth.maxWidth)
//        .opacity(isHidingPhotosView ? 0 : 1.0)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .disabled(isHidingPhotosView)
        
//        ZStack {
//          PhotosView(store: store.scope(state: \.photos, action: { .photos($0) }))
//            .opacity(!viewStore.isHidingImages ? 1.0 : 0.0)
//            .frame(
//              width: !viewStore.isHidingImages ? maxScreenWidth.maxWidth : 0,
//              height: !viewStore.isHidingImages ? maxScreenWidth.maxWidth : 0
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 15))
//            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
//            .padding([.bottom], !viewStore.isHidingImages ? 10 : 0 )
//          //            .padding([.bottom, .top], !viewStore.isHidingImages ? 10 : 0 )
//          
//          // This allows the expansion toggle animation to work properly.
//          Color.clear
//            .contentShape(Rectangle())
//            .frame(width: maxScreenWidth.maxWidth, height: 0)
//            .clipShape(RoundedRectangle(cornerRadius: 15))
//            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
//            .padding([.bottom], !viewStore.isHidingImages ? 10 : 0 )
//          //            .padding([.bottom, .top], !viewStore.isHidingImages ? 10 : 0 )
//        }
          
        // AboutListView
        if !viewStore.about.aboutSections.isEmpty {
          AboutListView(store: store.scope(state: \.about, action: { .about($0) }))
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          if !viewStore.about.isExpanded {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }
        }
        
        // IngredientListView
        if !viewStore.ingredients.ingredientSections.isEmpty {
          IngredientListView(store: store.scope(state: \.ingredients, action: { .ingredients($0) }))
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          if !viewStore.ingredients.isExpanded {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }
        }
        
        // StepListView
        if !viewStore.steps.stepSections.isEmpty {
          StepListView(store: store.scope(state: \.steps, action: { .steps($0) }))
            .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          if !viewStore.steps.isExpanded {
            Divider()
              .padding([.horizontal], maxScreenWidth.maxWidthHorizontalOffset)
          }
        }
        
        Spacer()
      }
      .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
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
              let aboutIsEmpty = viewStore.about.aboutSections.isEmpty
              Button {
                viewStore.send(.editSectionButtonTapped(.about, aboutIsEmpty ? .add : .delete), animation: .default)
              } label: {
                Label(aboutIsEmpty ? "Add About" : "Delete About", systemImage: "text.alignleft")
              }
              
              let ingredientsIsEmpty = viewStore.ingredients.ingredientSections.isEmpty
              Button {
                viewStore.send(.editSectionButtonTapped(.ingredients, ingredientsIsEmpty ? .add : .delete), animation: .default)
              } label: {
                Label(ingredientsIsEmpty ? "Add Ingredients" : "Delete Ingredients", systemImage: "checklist")
              }
              
              let stepsIsEmpty = viewStore.steps.stepSections.isEmpty
              Button {
                viewStore.send(.editSectionButtonTapped(.steps, stepsIsEmpty ? .add : .delete), animation: .default)
              } label: {
                Label(stepsIsEmpty ? "Add Steps" : "Delete Steps", systemImage: "list.number")
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
      .task {
        await viewStore.send(.task).finish()
      }
    }
  }
}

// MARK: - Previews
#Preview {
  NavigationStack {
    RecipeView(store: .init(
      initialState: RecipeReducer.State(
//        recipeID: .init()
        recipeID: .init(rawValue: .init(uuidString: "0BA83EA4-BEC6-4537-8227-A0AC03AAFB31")!)

      ),
      reducer: RecipeReducer.init
    ))
  }
}
