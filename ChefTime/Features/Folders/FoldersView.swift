import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FoldersView: View {
  let store: StoreOf<FoldersReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  var width: CGFloat { maxScreenWidth.maxWidth * 0.40 }
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
        List {
          Section {
            LazyVGrid(columns: columns, spacing: 10) {
              ForEach(viewStore.folders) { folder in
                FolderItemView(
                  folder: folder,
                  isEditing: viewStore.isEditing,
                  isSelected: viewStore.selection.contains(folder.id)
                )
                .frame(maxWidth: width)
                .onTapGesture {
                  if viewStore.isEditing {
                    viewStore.send(.folderSelectionTapped(folder.id), animation: .default)
                  }
                  else {
                    viewStore.send(.folderTapped(folder.id), animation: .default)
                  }
                }
              }
            }
            .transition(.scale)
            .animation(.easeInOut, value: viewStore.folders.count)
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
            .padding(.horizontal)
          } header: {
            Text("System Folders")
              .textTitleStyle()
            Spacer()
          }
          .accentColor(.primary)
          .disclosureGroupStyle(CustomDisclosureGroupStyle())
          .padding(.horizontal, 20)
          
          Section {
            LazyVGrid(columns: columns, spacing: 10) {
              ForEach(viewStore.folders) { folder in
                FolderItemView(
                  folder: folder,
                  isEditing: viewStore.isEditing,
                  isSelected: viewStore.selection.contains(folder.id)
                )
                .frame(maxWidth: width)
                .onTapGesture {
                  if viewStore.isEditing {
                    viewStore.send(.folderSelectionTapped(folder.id), animation: .default)
                  }
                  else {
                    viewStore.send(.folderTapped(folder.id), animation: .default)
                  }
                }
              }
            }
            .transition(.scale)
            .animation(.easeInOut, value: viewStore.folders.count)
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
            .padding(.horizontal)
          } header: {
            Text("User Folders")
              .textTitleStyle()
            Spacer()
          }
          .accentColor(.primary)
          .disclosureGroupStyle(CustomDisclosureGroupStyle())
          .padding(.horizontal, 20)
        }
        .background(Color(uiColor: .systemGray6))
        .listStyle(.sidebar)
        .navigationTitle(viewStore.navigationTitle)
        .toolbar { toolbar(viewStore: viewStore) }
        .searchable(
          text: .constant(""),
          placement: .navigationBarDrawer(displayMode: .always)
        )
        .environment(\.isHidingFolderImages, viewStore.isHidingFolderImages)
        .alert(store: store.scope(state: \.$alert, action: FoldersReducer.Action.alert))
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

//// MARK: - View
//struct FoldersView: View {
//  let store: StoreOf<FoldersReducer>
//  let columns: [GridItem] = [.init(), .init()]
//  @Environment(\.maxScreenWidth) var maxScreenWidth
//  @Environment(\.isHidingFolderImages) var isHidingFolderImages
//  var width: CGFloat { maxScreenWidth.maxWidth * 0.40 }
//
//  var body: some View {
//    WithViewStore(store, observe: { $0 }) { viewStore in
//      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
//        ScrollView {
//          DisclosureGroup(isExpanded: viewStore.$systemFoldersIsExpanded) {
//            LazyVGrid(columns: columns, spacing: 10) {
//              ForEach(viewStore.folders) { folder in
//                FolderItemView(
//                  folder: folder,
//                  isEditing: viewStore.isEditing,
//                  isSelected: viewStore.selection.contains(folder.id)
//                )
//                .frame(maxWidth: width)
//                .onTapGesture {
//                  if viewStore.isEditing {
//                    viewStore.send(.folderSelectionTapped(folder.id), animation: .default)
//                  }
//                  else {
//                    viewStore.send(.folderTapped(folder.id), animation: .default)
//                  }
//                }
//              }
//            }
//            .transition(.scale)
//            .animation(.easeInOut, value: viewStore.folders.count)
//            .listSectionSeparator(.hidden)
//            .listRowSeparator(.hidden)
//            .padding(.horizontal)
//          } label: {
//            Text("System Folders")
//              .textTitleStyle()
//            Spacer()
//          }
//          .accentColor(.primary)
//          .disclosureGroupStyle(CustomDisclosureGroupStyle())
//          .padding(.horizontal, 20)
//
//          DisclosureGroup(isExpanded: viewStore.$foldersIsExpanded) {
//            LazyVGrid(columns: columns, spacing: 10) {
//              ForEach(viewStore.folders) { folder in
//                FolderItemView(
//                  folder: folder,
//                  isEditing: viewStore.isEditing,
//                  isSelected: viewStore.selection.contains(folder.id)
//                )
//                .frame(maxWidth: width)
//                .onTapGesture {
//                  if viewStore.isEditing {
//                    viewStore.send(.folderSelectionTapped(folder.id), animation: .default)
//                  }
//                  else {
//                    viewStore.send(.folderTapped(folder.id), animation: .default)
//                  }
//                }
//              }
//            }
//            .transition(.scale)
//            .animation(.easeInOut, value: viewStore.folders.count)
//            .listSectionSeparator(.hidden)
//            .listRowSeparator(.hidden)
//            .padding(.horizontal)
//          } label: {
//            Text("User Folders")
//              .textTitleStyle()
//            Spacer()
//          }
//          .accentColor(.primary)
//          .disclosureGroupStyle(CustomDisclosureGroupStyle())
//          .padding(.horizontal, 20)
//        }
//        .background(Color(uiColor: .systemGray6))
//        .listStyle(.plain)
//        .navigationTitle(viewStore.navigationTitle)
//        .toolbar { toolbar(viewStore: viewStore) }
//        .searchable(
//          text: .constant(""),
//          placement: .navigationBarDrawer(displayMode: .always)
//        )
//        .environment(\.isHidingFolderImages, viewStore.isHidingFolderImages)
//        .alert(store: store.scope(state: \.$alert, action: FoldersReducer.Action.alert))
//      } destination: { state in
//        switch state {
//        case .folder:
//          CaseLet(
//            /FoldersReducer.PathReducer.State.folder,
//             action: FoldersReducer.PathReducer.Action.folder
//          ) {
//            FolderView(store: $0)
//          }
//        case .recipe:
//          CaseLet(
//            /FoldersReducer.PathReducer.State.recipe,
//             action: FoldersReducer.PathReducer.Action.recipe
//          ) {
//            RecipeView(store: $0)
//          }
//        }
//      }
//    }
//  }
//}

extension FoldersView {
  @ToolbarContentBuilder
  func toolbar(viewStore: ViewStoreOf<FoldersReducer>) -> some ToolbarContent {
    if viewStore.isEditing {
      ToolbarItemGroup(placement: .primaryAction) {
        Button("Done") {
          viewStore.send(.doneButtonTapped, animation: .default)
        }
      }
      
      ToolbarItemGroup(placement: .navigationBarLeading) {
        Button(viewStore.hasSelectedAll ? "Deselect All" : "Select All") {
          viewStore.send(.selectAllButtonTapped, animation: .default)
        }
      }
      
      ToolbarItemGroup(placement: .bottomBar) {
        Button("Move") {
          viewStore.send(.moveSelectedButtonTapped, animation: .default)
        }
        .disabled(viewStore.selection.isEmpty)
        Spacer()
        Button("Delete") {
          viewStore.send(.deleteSelectedButtonTapped, animation: .default)
        }
        .disabled(viewStore.selection.isEmpty)
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
        .accentColor(.primary)
      }
      
      ToolbarItemGroup(placement: .bottomBar) {
        Button {
          //          viewStore.send(.newFolderButtonTapped, animation: .default)
        } label: {
          Image(systemName: "folder.badge.plus")
        }
        Spacer()
        Text("\(viewStore.folders.count) folders")
        Spacer()
        Button {
          //          viewStore.send(.newRecipeButtonTapped, animation: .default)
        } label: {
          Image(systemName: "square.and.pencil")
          
        }
      }
    }
  }
}

// MARK: - Preview
struct FoldersView_Previews: PreviewProvider {
  static var previews: some View {
    //    NavigationStack {
    FoldersView(store: .init(
      initialState: .init(folders: .init(uniqueElements: Folder.longMock.folders)),
      reducer: FoldersReducer.init
    ))
    //    }
  }
}
