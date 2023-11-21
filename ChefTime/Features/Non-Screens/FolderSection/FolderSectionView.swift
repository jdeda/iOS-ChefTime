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
                viewStore.send(.folderTapped(id), animation: .default)
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

// MARK: - Preview
#Preview {
  ScrollView {
    FolderSectionView(
      store: .init(
        initialState: .init(
          title: "My Folder Section", folders: .init(uniqueElements: Folder.longMock.folders)
        ),
        reducer: FolderSectionReducer.init
      ),
      isEditing: false
    )
    .padding(20)
  }
}
