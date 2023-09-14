import SwiftUI
import ComposableArchitecture

/// MARK: - View
struct FolderView: View {
  let store: StoreOf<FolderReducer>
  let columns: [GridItem] = [.init(spacing: 20), .init(spacing: 20)]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollViewReader { proxy in
        ScrollView {
          
          // Folders
          FolderSectionView(
            store: store.scope(
              state: \.folders,
              action: FolderReducer.Action.folders
            ),
            isEditing: viewStore.isEditing == .folders
          )
          //          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          //          .opacity(viewStore.isEditing ? 0.0 : 1.0)
          //          .frame(maxHeight: viewStore.isEditing ? 0 : .infinity)
          .id(1)
          
          // Recipes.
          RecipeSectionView(
            store: store.scope(
              state: \.recipes,
              action: FolderReducer.Action.recipes
            ),
            isEditing: viewStore.isEditing == .recipes
          )
          //          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          //          .opacity(viewStore.userFoldersSection.folders.isEmpty ? 0.0 : 1.0)
          //          .frame(height: viewStore.recipes.isEmpty ? 0 : .infinity)
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
        .environment(\.isHidingFolderImages, viewStore.isHidingFolderImages)
        .alert(store: store.scope(state: \.$alert, action: FolderReducer.Action.alert))
      }
      .padding(.top, 1) // Prevent bizzare scroll view animations on hiding sections
    }
  }
}

extension FolderView {
  @ToolbarContentBuilder
  func toolbar(viewStore: ViewStoreOf<FolderReducer>) -> some ToolbarContent {
    if viewStore.isEditing != nil {
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
          Button {
            viewStore.send(.selectFoldersButtonTapped, animation: .default)
          } label: {
            Label("Select Folders", systemImage: "checkmark.circle")
          }
          Button {
            viewStore.send(.hideImagesButtonTapped, animation: .default)
          } label: {
            Label(viewStore.isHidingFolderImages ? "Unhide Images" : "Hide Images", systemImage: "photo.stack")
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
        Text("\(viewStore.folders.folders.count) folders * \(viewStore.recipes.recipes.count) recipes")
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
      let folder  = FolderGridItemReducer.State(id: .init(), folder: Folder.longMock)
      FolderView(store: .init(
        initialState: .init(
          folders: .init(title: "Folders", folders: .init(uniqueElements: folder.folder.folders.map {
            .init(id: .init(), folder: $0)
          })),
          recipes: .init(title: "Recipes", recipes: .init(uniqueElements: folder.folder.recipes.map {
            .init(id: .init(), recipe: $0)
          }))
        ),
        reducer: FolderReducer.init
      ))
    }
  }
}
