import SwiftUI
import ComposableArchitecture

// TODO: Add a scroll to feature when expanding/collapsing

/// How to simply this feature?
/// 1. Break sections into their own features...
///   - This means you must do the following:
///     1. make the system folders an array
///     2. delete all the boilerplate for having separate instances
///     3. just assume when working with the array you have those three values in a specific order, and or just check the element folderType,
///      yes its a bit dangerous, but you have to be a moron to forget these rules

/// Folder Types
///   1. System
///   ///   any of these, you cannot:
///           - delete this folder
///         - rename this folder
///         - move this folder
///     1. All
///         - editing actually edits other folders simealtaneiously
///         - if i add when in the root it automatically adds to the standard
///     2. Standard
///          - behaves just like a user folder, with the exception of the root not being able to delete,rename/move
///     3. Recently Deleted
///     - cannot do anything but scroll and recover the recipe
///     - cannot have folders
///   2. User
///     You can do anything

/// MARK: - View
struct FoldersView: View {
  let store: StoreOf<FoldersReducer>
  let columns: [GridItem] = [.init(spacing: 20), .init(spacing: 20)]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
        ScrollViewReader { proxy in
          ScrollView {
            
            // System Folders.
            FolderSectionView(
              store: store.scope(
                state: \.systemFoldersSection,
                action: FoldersReducer.Action.systemFoldersSection
              ),
              isEditing: viewStore.isEditing
            )
            .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
            .opacity(viewStore.isEditing ? 0.0 : 1.0)
            .frame(maxHeight: viewStore.isEditing ? 0 : .infinity)
            .id(1)
            
            // User Folders.
            FolderSectionView(
              store: store.scope(
                state: \.userFoldersSection,
                action: FoldersReducer.Action.userFoldersSection
              ),
              isEditing: viewStore.isEditing
            )
            .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
            .opacity(viewStore.userFoldersSection.folders.isEmpty ? 0.0 : 1.0)
            .frame(height: viewStore.userFoldersSection.folders.isEmpty ? 0 : .infinity)
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
          .task { await viewStore.send(.task).finish() }
          .environment(\.isHidingFolderImages, viewStore.isHidingFolderImages)
          .alert(store: store.scope(state: \.$alert, action: FoldersReducer.Action.alert))
        }
        .padding(.top, 1) // Prevent bizzare scroll view animations on hiding sections
      } destination: { state in
        switch state {
        case .folder:
          CaseLet(
            /FoldersReducer.PathReducer.State.folder,
             action: FoldersReducer.PathReducer.Action.folder
          ) {
            FolderView(store: $0)
          }
        case .recipe:
          CaseLet(
            /FoldersReducer.PathReducer.State.recipe,
             action: FoldersReducer.PathReducer.Action.recipe
          ) {
            RecipeView(store: $0)
          }
        }
      }
    }
  }
}

extension FoldersView {
  @ToolbarContentBuilder
  func toolbar(viewStore: ViewStoreOf<FoldersReducer>) -> some ToolbarContent {
    if viewStore.isEditing {
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
        .disabled(viewStore.userFoldersSection.selection.isEmpty)
        .accentColor(.yellow)
        Spacer()
        Button("Delete") {
          viewStore.send(.deleteSelectedButtonTapped, animation: .default)
        }
        .disabled(viewStore.userFoldersSection.selection.isEmpty)
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
        Text("\(viewStore.userFoldersSection.folders.count) folders")
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
struct FoldersView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FoldersView(store: .init(
        initialState: .init(),
        reducer: FoldersReducer.init
      ))
    }
  }
}
