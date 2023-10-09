import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FolderView: View {
  let store: StoreOf<FolderReducer>
  @Environment(\.maxScreenWidth) private var maxScreenWidth
  @Environment(\.isHidingImages) private var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollViewReader { proxy in
        ScrollView {
          
          // Folders
          let isHidingFolders = viewStore.editStatus == .recipes || viewStore.folderSection.folders.isEmpty
          FolderSectionView(
            store: store.scope(
              state: \.folderSection,
              action: FolderReducer.Action.folders
            ),
            isEditing: !isHidingFolders && viewStore.editStatus == .folders
          )
          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          .opacity(isHidingFolders ? 0.0 : 1.0)
          .frame(maxHeight: isHidingFolders ? 0 : .infinity)
          .disabled(isHidingFolders)
          .id(1)
          
          // Recipes.
          let isHidingRecipes = viewStore.editStatus == .folders || viewStore.recipeSection.recipes.isEmpty
          RecipeSectionView(
            store: store.scope(
              state: \.recipeSection,
              action: FolderReducer.Action.recipes
            ),
            isEditing: !isHidingRecipes && viewStore.editStatus == .recipes
          )
          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          .opacity(isHidingRecipes ? 0.0 : 1.0)
          .frame(maxHeight: isHidingRecipes ? 0 : .infinity)
          .disabled(isHidingRecipes)
          .id(2)
        }
        
        .navigationTitle(viewStore.navigationTitle)
        .toolbar { toolbar(viewStore: viewStore) }
        .searchable(
          text: .constant(""),
          placement: .navigationBarDrawer(displayMode: .always)
        )
        .onChange(of: viewStore.scrollViewIndex) { newScrollViewIndex in
          withAnimation {
            proxy.scrollTo(newScrollViewIndex, anchor: .center)
          }
        }
        .environment(\.isHidingImages, viewStore.isHidingImages)
        .alert(store: store.scope(state: \.$alert, action: FolderReducer.Action.alert))
      }
      .padding(.top, 1) // Prevent bizzare scroll view animations on hiding sections
    }
  }
}

// MARK: - Toolbar
extension FolderView {
  @ToolbarContentBuilder
  func toolbar(viewStore: ViewStoreOf<FolderReducer>) -> some ToolbarContent {
    if viewStore.editStatus != nil {
      ToolbarItemGroup(placement: .primaryAction) {
        Button("Done") {
          viewStore.send(.doneButtonTapped, animation: .default)
        }
        .accentColor(.yellow)
      }
      
      ToolbarItemGroup(placement: .navigationBarLeading) {
        Button(viewStore.hasSelectedAll ? "Deselect All" : "Select All") {
          viewStore.send(.selectAllButtonTapped, animation: .default)
        }
        .accentColor(.yellow)
      }
      
      ToolbarItemGroup(placement: .bottomBar) {
        Button("Move") {
          viewStore.send(.moveSelectedButtonTapped, animation: .default)
        }
        //        .disabled(viewStore.userFoldersSection.selection.isEmpty)
        .accentColor(.yellow)
        Spacer()
        Button("Delete") {
          viewStore.send(.deleteSelectedButtonTapped, animation: .default)
        }
        //        .disabled(viewStore.userFoldersSection.selection.isEmpty)
        .accentColor(.yellow)
      }
    }
    else {
      ToolbarItemGroup(placement: .primaryAction) {
        Menu {
          if !viewStore.folderSection.folders.isEmpty {
            Button {
              viewStore.send(.selectFoldersButtonTapped, animation: .default)
            } label: {
              Label("Select Folders", systemImage: "checkmark.circle")
            }
          }
          if !viewStore.recipeSection.recipes.isEmpty {
            Button {
              viewStore.send(.selectRecipesButtonTapped, animation: .default)
            } label: {
              Label("Select Recipes", systemImage: "checkmark.circle")
            }
          }
          Button {
            viewStore.send(.toggleHideImagesButtonTapped, animation: .default)
          } label: {
            Label(viewStore.isHidingImages ? "Unhide Images" : "Hide Images", systemImage: "photo.stack")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .accentColor(.yellow)
      }
      ToolbarItemGroup(placement: .bottomBar) {
        Button {
          viewStore.send(.newFolderButtonTapped, animation: .default)
        } label: {
          Image(systemName: "folder.badge.plus")
        }
        .accentColor(.yellow)
        Spacer()
        // TODO: Update this count when all the folders are fetched properly
        Text("\(viewStore.folderSection.folders.count) folders • \(viewStore.recipeSection.recipes.count) recipes")
        Spacer()
        Button {
          viewStore.send(.newRecipeButtonTapped, animation: .default)
        } label: {
          Image(systemName: "square.and.pencil")
        }
        .accentColor(.yellow)
      }
    }
  }
}

// MARK: - Preview
struct FolderView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FolderView(store: .init(
        initialState: .init(folder: Folder.longMock),
        reducer: FolderReducer.init
      ))
    }
  }
}
