import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FolderSectionView: View {
  let store: StoreOf<FolderSectionReducer>
  let isEditing: Bool
  private let columns = Array(repeating: GridItem(spacing: 20, alignment: .top), count: 2)
  @Environment(\.isHidingImages) private var isHidingImages

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: \.isExpanded,
        send: { .binding(.set(\.$isExpanded, isEditing ? viewStore.isExpanded : $0)) }
      )) {
        LazyVGrid(columns: columns, spacing: 10) {
          ForEachStore(store.scope(
            state: \.folders,
            action: FolderSectionReducer.Action.folders
          )) { childStore in
            let id = ViewStore(childStore, observe: \.id).state
            FolderGridItemView(
              store: childStore,
              isEditing: isEditing,
              isSelected: viewStore.selection.contains(id)
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: viewStore.isExpanded ? .infinity : 0.0, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .opacity(viewStore.isExpanded ? 1.0 : 0.0)
            .onTapGesture {
              if isEditing {
                viewStore.send(.folderSelected(id), animation: .default)
              }
              else {
                viewStore.send(.delegate(.folderTapped(id)), animation: .default)
              }
            }
          }
        }
        .animation(.default, value: viewStore.folders.count)
      } label: {
        Text(viewStore.title)
          .textTitleStyle()
        Spacer()
      }
      .accentColor(.yellow)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
    }
  }
}

// MARK: - Reducer
struct FolderSectionReducer: Reducer {
  struct State: Equatable {
    let title: String
    var folders: IdentifiedArrayOf<FolderGridItemReducer.State> = []
    @BindingState var isExpanded: Bool = true
    @BindingState var selection = Set<FolderGridItemReducer.State.ID>()
  }
  
  enum Action: Equatable, BindableAction {
    case folderSelected(FolderGridItemReducer.State.ID)
    case folders(FolderGridItemReducer.State.ID, FolderGridItemReducer.Action)
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .folderSelected(id):
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        
        return .none
        
      case let .folders(id, .delegate(action)):
        switch action {
        case .move:
          break
        case .delete:
          state.folders.remove(id: id)
          break
        }
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

// MARK: - DelegateAction
extension FolderSectionReducer {
  enum DelegateAction: Equatable {
    case folderTapped(FolderGridItemReducer.State.ID)
  }
}

// MARK: - Preview
struct FolderSectionView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      FolderSectionView(
        store: .init(
          initialState: .init(
            title: "My Folder Section", folders: .init(uniqueElements: Folder.longMock.folders.map { .init(id: .init(), folder: $0) })
          ),
          reducer: FolderSectionReducer.init
        ),
        isEditing: false
      )
      .padding(20)
    }
  }
}
