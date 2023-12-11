import SwiftUI
import ComposableArchitecture

struct GridSectionView<ID: Equatable & Hashable>: View {
  let store: StoreOf<GridSectionReducer<ID>>
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
          // I have IDs that I need to use to perform certain actions...
          ForEachStore(store.scope(state: \.gridItems, action: GridSectionReducer.Action.gridItems)) { childStore in
            // It appears that whenever I select a value, the entire array of child views is completely redrawn (from scratch?)
//            let id = ViewStore(childStore, observe: \.id).state
            GridItemView(
              store: childStore,
              isEditing: isEditing
//              isSelected: viewStore.selection.contains(id)
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: viewStore.isExpanded ? .infinity : 0.0, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .opacity(viewStore.isExpanded ? 1.0 : 0.0)
//            .padding()
//            .background(.random)
//            .onTapGesture {
//              if isEditing {
//                viewStore.send(.gridItemSelected(id), animation: .default)
//              }
//              else {
//                viewStore.send(.delegate(.gridItemTapped(id)), animation: .default)
//              }
//            }
          }
        }
        .animation(.default, value: viewStore.gridItems.count)
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

#Preview {
  ScrollView {
    GridSectionView<Folder.ID>(
      store: .init(
        initialState: .init(gridItems: Folder.shortMock.recipes.map({
          .init(id: .init(rawValue: $0.id.rawValue), name: $0.name, description: $0.lastEditDate.formattedDate, imageData: $0.imageData.first)
        })),
        reducer: GridSectionReducer.init
      ),
      isEditing: false
    )
    .padding(20)
  }
}
