import SwiftUI
import ComposableArchitecture

struct FolderView: View {
  let store: StoreOf<FolderReducer>
  @Environment(\.maxScreenWidth) private var maxScreenWidth
  @Environment(\.isHidingImages) private var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        ScrollView {
          // Folders.
          GridSectionView(
            store: store.scope(state: \.folderSection, action: FolderReducer.Action.folderSection),
            isEditing: !viewStore.isHidingFolders && viewStore.editStatus == .folders
          )
          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          .opacity(viewStore.isHidingFolders ? 0.0 : 1.0)
          .frame(maxHeight: viewStore.isHidingFolders ? 0 : .infinity)
          .disabled(viewStore.isHidingFolders)
          .id(1)
          
          // Recipes.
          GridSectionView(
            store: store.scope(state: \.recipeSection, action: FolderReducer.Action.recipeSection),
            isEditing: !viewStore.isHidingRecipes && viewStore.editStatus == .recipes
          )
          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          .opacity(viewStore.isHidingRecipes ? 0.0 : 1.0)
          .frame(maxHeight: viewStore.isHidingRecipes ? 0 : .infinity)
          .disabled(viewStore.isHidingRecipes)
          .id(2)
        }
        
        .navigationTitle(viewStore.navigationTitle)
        .navigationBarBackButtonHidden(viewStore.editStatus != nil)
        .toolbar { toolbar(viewStore: viewStore) }
        .searchable(
          text: viewStore.binding(
            get: { $0.search.query },
            send: { .search(.setQuery($0) )}
          ),
          placement: .navigationBarDrawer(displayMode: .always)
        ) {
          SearchView(store: store.scope(
            state: \.search,
            action: FolderReducer.Action.search
          ))
        }
        .alert(
          store: store.scope(state: \.$destination, action: FolderReducer.Action.destination),
          state: /FolderReducer.DestinationReducer.State.alert,
          action: FolderReducer.DestinationReducer.Action.alert
        )
        .alert("Rename", isPresented: .constant(viewStore.destination == .renameFolderAlert)) {
          RenameAlert(name: viewStore.folder.name) {
            viewStore.send(.acceptFolderNameButtonTapped($0), animation: .default)
          } cancel: {
            viewStore.send(.destination(.dismiss), animation: .default)
          }
        }
        .alert("New Folder", isPresented: .constant(viewStore.destination == .nameNewFolderAlert), actions: {
          RenameAlert(name: "") {
            viewStore.send(.acceptNewFolderNameButtonTapped($0), animation: .default)
          } cancel: {
            viewStore.send(.destination(.dismiss), animation: .default)
          }
        }, message: {
          Text("Enter a name for this folder.")
        })
        .alert("New Recipe", isPresented: .constant(viewStore.destination == .nameNewRecipeAlert), actions: {
          RenameAlert(name: "") {
            viewStore.send(.acceptNewRecipeNameButtonTapped($0), animation: .default)
          } cancel: {
            viewStore.send(.destination(.dismiss), animation: .default)
          }
        }, message: {
          Text("Enter a name for this recipe.")
        })
        .environment(\.isHidingImages, viewStore.isHidingImages)
        .padding(.top, 1) // Prevent bizzare scroll view animations on hiding sections
      }
      .task { await viewStore.send(.task).finish() }
      .disabled(viewStore.loadStatus == .isLoading)
      .blur(radius: viewStore.loadStatus == .isLoading ? 1.0 : 0.0)
      .overlay {
        ProgressView()
          .opacity(viewStore.loadStatus == .isLoading ? 1.0 : 0.0)
      }
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
          if !viewStore.folderSection.gridItems.isEmpty {
            Button {
              viewStore.send(.selectFoldersButtonTapped, animation: .default)
            } label: {
              Label("Select Folders", systemImage: "checkmark.circle")
            }
          }
          if !viewStore.recipeSection.gridItems.isEmpty {
            Button {
              viewStore.send(.selectRecipesButtonTapped, animation: .default)
            } label: {
              Label("Select Recipes", systemImage: "checkmark.circle")
            }
          }
          Button {
            viewStore.send(.renameFolderButtonTapped, animation: .default)
          } label: {
            Label("Rename", systemImage: "pencil")
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
        Text("\(viewStore.folderSection.gridItems.count) folders • \(viewStore.recipeSection.gridItems.count) recipes")
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

#Preview {
  NavigationStack {
    FolderView(store: .init(
      initialState: .init(folder: Folder.longMock),
      reducer: FolderReducer.init
    ))
  }
}

extension ShapeStyle where Self == Color {
  static var random: Color {
    Color(
      red: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1)
    )
  }
}
