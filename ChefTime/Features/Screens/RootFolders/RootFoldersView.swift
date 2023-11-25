import SwiftUI
import ComposableArchitecture

struct RootFoldersView: View {
  let store: StoreOf<RootFoldersReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingImages) var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollViewReader { proxy in
        ScrollView {
          
          // System Folders.
          GridSectionView(
            store: store.scope(state: \.systemFoldersSection, action: { .systemFoldersSection($0) }),
            isEditing: viewStore.isEditing
          )
          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          .opacity(viewStore.isEditing ? 0.0 : 1.0)
          .frame(maxHeight: viewStore.isEditing ? 0 : .infinity)
          .id(1)
          
          // User Folders.
          GridSectionView(
            store: store.scope(state: \.userFoldersSection, action: { .userFoldersSection($0) }),
            isEditing: viewStore.isEditing
          )
          .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
          .opacity(viewStore.userFoldersSection.gridItems.isEmpty ? 0.0 : 1.0)
          .frame(maxHeight: viewStore.userFoldersSection.gridItems.isEmpty ? 0 : .infinity)
          .id(2)
        }
        
        .navigationTitle(viewStore.navigationTitle)
        .toolbar { toolbar(viewStore: viewStore) }
        .searchable(
          text: .constant(""),
          placement: .navigationBarDrawer(displayMode: .always)
        )
        .onChange(of: viewStore.scrollViewIndex) { _, newScrollViewIndex in
          withAnimation {
            proxy.scrollTo(newScrollViewIndex, anchor: .center)
          }
        }
        .task { await viewStore.send(.task).finish() }
        .environment(\.isHidingImages, viewStore.isHidingImages)
        .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
      }
      .padding(.top, 1) // Prevent bizzare scroll view animations on hiding sections
    }
  }
}

extension RootFoldersView {
  @ToolbarContentBuilder
  func toolbar(viewStore: ViewStoreOf<RootFoldersReducer>) -> some ToolbarContent {
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
          if !viewStore.userFoldersSection.gridItems.isEmpty {
            Button {
              viewStore.send(.selectFoldersButtonTapped, animation: .default)
            } label: {
              Label("Select Folders", systemImage: "checkmark.circle")
            }
          }
          Button {
            viewStore.send(.hideImagesButtonTapped, animation: .default)
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
        Text("\(viewStore.userFoldersSection.gridItems.count) folders")
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
    RootFoldersView(store: .init(
      initialState: .init(),
      reducer: RootFoldersReducer.init
    ))
  }
}
