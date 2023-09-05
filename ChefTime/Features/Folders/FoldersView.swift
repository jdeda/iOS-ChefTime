import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FoldersView: View {
  let store: StoreOf<FoldersReducer>
  let columns: [GridItem] = [.init(spacing: 20), .init(spacing: 20)]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  var width: CGFloat { maxScreenWidth.maxWidth * 0.40 }
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
        List {
          Section {
            LazyVGrid(columns: columns, spacing: 10) {
              FolderItemView(folder: viewStore.systemAllFolder, isEditing: false, isSelected: false)
                .onTapGesture {
                  viewStore.send(.systemFolderTapped(.systemAll), animation: .default)
                }
              
              FolderItemView(folder: viewStore.systemStandardFolder, isEditing: false, isSelected: false)
                .onTapGesture {
                  viewStore.send(.systemFolderTapped(.systemStandard), animation: .default)
                }
              
              FolderItemView(folder: viewStore.systemRecentlyDeletedFolder, isEditing: false, isSelected: false)
                .onTapGesture {
                  viewStore.send(.systemFolderTapped(.systemRecentlyDeleted), animation: .default)
                }
            }
            .animation(.default, value: viewStore.userFolders.count)
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
          } header: {
            Text("System")
              .textSubtitleStyle()
          }
          .textCase(nil)
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
          .listSectionSeparator(.hidden)
                    
          Section {
            LazyVGrid(columns: columns, spacing: 10) {
              ForEach(viewStore.userFolders) { folder in
                FolderItemView(
                  folder: folder,
                  isEditing: viewStore.isEditing,
                  isSelected: viewStore.selection.contains(folder.id)
                )
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
            .animation(.default, value: viewStore.userFolders.count)
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
          } header: {
            Text("User")
              .textSubtitleStyle()
          }
          .textCase(nil)
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
          .listSectionSeparator(.hidden)
        }
        .listStyle(.sidebar)
        .navigationTitle(viewStore.navigationTitle)
        .toolbar { toolbar(viewStore: viewStore) }
        .searchable(
          text: .constant(""),
          placement: .navigationBarDrawer(displayMode: .always)
        )
        .task {
          await viewStore.send(.task).finish()
        }
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
        Text("\(viewStore.userFolders.count) folders")
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
    NavigationStack {
      FoldersView(store: .init(
        initialState: .init(userFolders: .init(uniqueElements: Folder.longMock.folders)),
        reducer: FoldersReducer.init
      ))
    }
  }
}


struct Database {
  let fetchAllRecipes: @Sendable () -> AsyncStream<Recipe>
}

extension Database: DependencyKey {
  static let liveValue = Self.live
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue}
  }
}

extension Database {
  static let live = Self(
    fetchAllRecipes: {
      .init { continuation in
        let task = Task {
          await withTaskGroup(of: Void.self) { taskGroup in
            for num in 1...26 {
              taskGroup.addTask {
                let io = ReadWriteIO(fileName: "recipe_\(num < 10 ? "0\(num)" : "\(num)")", fileExtension: ".json")
                let recipe = io.readRecipeFromDisk()
                continuation.yield(recipe)
              }
            }
          }
          continuation.finish()
        }
        continuation.onTermination = { _  in
          task.cancel()
        }
      }
    }
  )
}

// MARK: - ReadWriteIO
struct ReadWriteIO {
  let fileName: String
  let fileExtension: String
  
  var fileURL: URL {
    Bundle.main.url(forResource: fileName, withExtension: fileExtension)!
  }
  
  func writeRecipeToDisk(_ recipe: Recipe) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(recipe)
    try! data.write(to: fileURL, options: .atomic)
  }
  
  func readRecipeFromDisk() -> Recipe {
    let data = try! Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let recipe = try! decoder.decode(Recipe.self, from: data)
    return recipe
  }
}
