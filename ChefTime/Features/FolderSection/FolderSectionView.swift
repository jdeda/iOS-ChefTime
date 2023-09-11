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
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
        LazyVGrid(columns: columns, spacing: 10) {
          ForEachStore(store.scope(
            state: \.folders,
            action: FolderSectionReducer.Action.folders
          )) { childStore in
            let id = ViewStore(childStore, observe: \.id).state
            FolderGridItemView(
              store: childStore,
              isEditing: viewStore.isEditing,
              isSelected: viewStore.selection.contains(id)
            )
            .onTapGesture {
              viewStore.send(.delegate(.folderTapped(id)), animation: .default)
            }
          }
        }
        .animation(.default, value: viewStore.folders.count)
      } label: {
        Text(viewStore.title)
          .textSubtitleStyle()
        Spacer()
      }
      .accentColor(.primary)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
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
    @BindingState var isExpanded: Bool = true
  }
  
  enum Action: Equatable, BindableAction {
    case folders(FolderGridItemReducer.State.ID, FolderGridItemReducer.Action)
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .folders(id, .delegate(action)):
        return .none
        
      case .folders, .binding, .delegate:
        return .none
      }
    }
    .forEach(\.folders, action: /Action.folders) {
      FolderGridItemReducer()
    }
    
  }
}

extension FolderSectionReducer {
  enum DelegateAction: Equatable {
    case folderTapped(FolderGridItemReducer.State.ID)
  }
}

// MARK: - Preview
struct FolderSectionView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      FolderSectionView(store: .init(
        initialState: .init(
          folders: .init(uniqueElements: Folder.longMock.folders.map { .init(id: .init(), folder: $0) }),
          title: "My Folder Section"
        ),
        reducer: FolderSectionReducer.init
      ))
    }
//    .listStyle(.sidebar)
  }
}

