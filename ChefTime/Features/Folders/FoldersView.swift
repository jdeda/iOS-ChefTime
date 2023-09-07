import SwiftUI
import ComposableArchitecture


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
  var width: CGFloat { maxScreenWidth.maxWidth * 0.40 }
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
        List {
          Section {
            LazyVGrid(columns: columns, spacing: 10) {
              FolderGridItemView(
                store: store.scope(
                  state: \.systemAllFolder,
                  action: FoldersReducer.Action.systemAllFolder
                ),
                isEditing: false,
                isSelected: false
              )
              FolderGridItemView(
                store: store.scope(
                  state: \.systemStandardFolder,
                  action: FoldersReducer.Action.systemStandardFolder
                ),
                isEditing: false,
                isSelected: false
              )
              FolderGridItemView(
                store: store.scope(
                  state: \.systemRecentlyDeletedFolder,
                  action: FoldersReducer.Action.systemRecentlyDeletedFolder
                ),
                isEditing: false,
                isSelected: false
              )
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
              ForEachStore(store.scope(
                state: \.userFolders,
                action: FoldersReducer.Action.userFolder
              )) { childStore in
                FolderGridItemView(
                  store: childStore,
                  isEditing: viewStore.isEditing,
                  isSelected: viewStore.selection.contains(ViewStore(childStore, observe: \.id).state)
                )
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
        if viewStore.userFolders.isEmpty {
          await viewStore.send(.task).finish()
        }
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
        initialState: .init(),
        reducer: FoldersReducer.init
      ))
    }
  }
}

// MARK: - Temporary DB
struct Database {
  let fetchAllFolders: @Sendable () -> AsyncStream<Folder>
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
    fetchAllFolders: {
      .init { continuation in
        let task = Task {
          var rootURL = URL(string: "/Users/jessededa/Developement/Swift/03_Apps_TCA/ChefTime/ChefTime/Resources/JSON/user")!
          guard let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
            options: .skipsHiddenFiles
          )
          else {
            continuation.finish()
            return
          }
          
          for url in contents {
            guard let folder = await fetchFolder(at: url)
            else { continue }
            continuation.yield(folder)
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

/// Assume directory is a user folder.
private func fetchFolder(at directoryURL: URL) async -> Folder? {
  guard let contents = try? FileManager.default.contentsOfDirectory(
    at: directoryURL,
    includingPropertiesForKeys: [.fileResourceTypeKey, .contentTypeKey, .nameKey],
    options: .skipsHiddenFiles
  )
  else { return nil }
  
  var folder = Folder(id: .init(), name: directoryURL.lastPathComponent, folderType: .user)
  for url in contents {
    if url.hasDirectoryPath {
      guard let childFolder = await fetchFolder(at: url)
      else { continue }
      folder.folders.append(childFolder)
    }
    else if url.pathExtension.lowercased() == "json" {
      guard let recipe = await fetchRecipe(at: url)
      else { continue }
      folder.recipes.append(recipe)
    }
    else {
      continue
    }
  }
  return folder
}

private func fetchRecipe(at url: URL) async -> Recipe? {
  guard let data = try? Data(contentsOf: url),
        let recipe = try? JSONDecoder().decode(Recipe.self, from: data)
  else { return nil }
  return recipe
}
