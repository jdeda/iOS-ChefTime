import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FolderSectionView: View {
  let store: StoreOf<FolderSectionReducer>
  @Environment(\.maxScreenWidth) private var maxScreenWidth
  @Environment(\.isHidingFolderImages) private var isHidingFolderImages
  private var width: CGFloat { maxScreenWidth.maxWidth * 0.40 }
  private let columns: [GridItem] = [.init(spacing: 20), .init(spacing: 20)]

  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Section {
        LazyVGrid(columns: columns, spacing: 10) {
          ForEachStore(store.scope(
            state: \.folders,
            action: FolderSectionReducer.Action.folders
          )) { childStore in
            FolderGridItemView(
              store: childStore,
              isEditing: viewStore.isEditing,
              isSelected: viewStore.selection.contains(ViewStore(childStore, observe: \.id).state)
            )
          }
        }
        .animation(.default, value: viewStore.folders.count)
        .listSectionSeparator(.hidden)
        .listRowSeparator(.hidden)
      } header: {
        Text(viewStore.title)
          .textSubtitleStyle()
      }
      .textCase(nil)
      .listRowBackground(Color.clear)
      .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
      .listSectionSeparator(.hidden)
    }
  }
}

// MARK: - Reducer
struct FolderSectionReducer: Reducer {
  struct State: Equatable {
    var folders: IdentifiedArrayOf<FolderGridItemReducer.State> = []
    let title: String
    var isEditing: Bool = false
    @BindingState var selection = Set<FolderGridItemReducer.State.ID>()
  }
  
  enum Action: Equatable, BindableAction {
    case folders(FolderGridItemReducer.State.ID, FolderGridItemReducer.Action)
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .folders(id, .delegate(action)):
        return .none
        
      case .folders, .binding:
        return .none
      }
    }
    .forEach(\.folders, action: /Action.folders) {
      FolderGridItemReducer()
    }
    
  }
}

// MARK: - Preview
struct FolderSectionView_Previews: PreviewProvider {
  static var previews: some View {
    List {
      FolderSectionView(store: .init(
        initialState: .init(
          folders: .init(uniqueElements: Folder.longMock.folders.map { .init(id: .init(), folder: $0) }),
          title: "My Folder Section"
        ),
        reducer: FolderSectionReducer.init
      ))
    }
    .listStyle(.sidebar)
  }
}

