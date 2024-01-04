import SwiftUI
import ComposableArchitecture

struct RootFoldersView: View {
  let store: StoreOf<RootFoldersReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingImages) var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        if viewStore.loadStatus == .isLoading {
          ProgressView()
        }
        else {
          ScrollView {
            GridSectionView(
              store: store.scope(state: \.userFoldersSection, action: RootFoldersReducer.Action.userFoldersSection),
              isEditing: viewStore.isEditing
            )
            .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
            .opacity(viewStore.userFoldersSection.gridItems.isEmpty ? 0.0 : 1.0)
            .frame(maxHeight: viewStore.userFoldersSection.gridItems.isEmpty ? 0 : .infinity)
          }
          .navigationTitle(viewStore.navigationTitle)
          .navigationBarBackButtonHidden(viewStore.isEditing)
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
              action: RootFoldersReducer.Action.search
            ))
          }
          .alert(
            store: store.scope(state: \.$destination, action: RootFoldersReducer.Action.destination),
            state: /RootFoldersReducer.DestinationReducer.State.alert,
            action: RootFoldersReducer.DestinationReducer.Action.alert
          )
          .alert("New Folder", isPresented: .constant(viewStore.destination == .nameNewFolderAlert), actions: {
            RenameAlert(name: "") {
              viewStore.send(.acceptFolderNameButtonTapped($0), animation: .default)
            } cancel: {
              viewStore.send(.destination(.dismiss), animation: .default)
            }
          }, message: {
            Text("Enter a name for this folder.")
          })
          .environment(\.isHidingImages, viewStore.isHidingImages)
          .padding(.top, 1) // Prevent bizzare scroll view animations on hiding sections
        }
      }
      .task { await viewStore.send(.task).finish() }
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
