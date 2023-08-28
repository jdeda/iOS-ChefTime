import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FoldersView: View {
  let store: StoreOf<FoldersReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
        ScrollView {
          LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewStore.folders) { folder in
              let image = folder.recipes.first?.imageData.first?.image ?? Image(systemName: "folder")
              GridItemView(
                image: image,
                title: folder.name,
                subTitle: "Foo"
              )
              .onTapGesture { viewStore.send(.folderTapped(folder.id)) }
            }
          }
          .padding(.horizontal)
        }
        .navigationTitle("Folders")
        .searchable(
          text: .constant(""),
          placement: .navigationBarDrawer(displayMode: .always)
        )
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
  
  struct GridItemView: View {
    let width = UIScreen.main.bounds.width * 0.40
    let image: Image
    let title: String
    let subTitle: String
    
    var body: some View {
      VStack {
        self.image
          .resizable()
          .frame(width: width, height: width)
          .clipShape(RoundedRectangle(cornerRadius: 15))
        Text(self.title)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text(self.subTitle)
          .lineLimit(2)
          .font(.body)
        Spacer()
      }
      .frame(maxWidth: width)
    }
  }
}

// MARK: - Reducer
struct FoldersReducer: Reducer {
  struct State: Equatable {
    var path = StackState<PathReducer.State>()
    var folders: IdentifiedArrayOf<Folder>
  }
  
  enum Action: Equatable {
    case path(StackAction<PathReducer.State, PathReducer.Action>)
    case folderTapped(Folder.ID)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .folderTapped(id):
        guard let folder = state.folders[id: id] else { return .none }
        state.path.append(.folder(.init(folder: folder)))
        return .none
        
      case let .path(action):
        switch action {
        case let .element(id: stackID, action: .folder(.delegate(action))):
          switch action {
          case let .folderTapped(folderID):
            guard case let .folder(folder) = state.path[id: stackID],
                  let childFolder = folder.folder.folders[id: folderID]
            else { return .none }
            state.path.append(.folder(.init(folder: childFolder)))
            return .none
            
          case let .recipeTapped(recipeID):
            guard case let .folder(folder) = state.path[id: stackID],
                  let recipe = folder.folder.recipes[id: recipeID]
            else { return .none }
            state.path.append(.recipe(.init(recipe: recipe)))
            return .none
          }
          
        case .element:
          return .none
          
        default:
          return .none
        }
      }
    }
    .forEach(\.path, action: /Action.path) {
      PathReducer()
    }
  }
}

extension FoldersReducer {
  struct PathReducer: Reducer {
    enum State: Equatable {
      case folder(FolderReducer.State)
      case recipe(RecipeReducer.State)
    }
    
    enum Action: Equatable {
      case folder(FolderReducer.Action)
      case recipe(RecipeReducer.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: /State.folder, action: /Action.folder) {
        FolderReducer()
      }
      Scope(state: /State.recipe, action: /Action.recipe) {
        RecipeReducer()
      }
    }
  }
}

// MARK: - Preview
struct FoldersView_Previews: PreviewProvider {
  static var previews: some View {
    FoldersView(store: .init(
      initialState: .init(folders: .init(uniqueElements: Folder.longMock.folders)),
      reducer: FoldersReducer.init
    ))
  }
}

