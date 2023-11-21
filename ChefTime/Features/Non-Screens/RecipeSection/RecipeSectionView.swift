import SwiftUI
import ComposableArchitecture

// MARK: - View
struct RecipeSectionView: View {
  let store: StoreOf<RecipeSectionReducer>
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
            state: \.recipes,
            action: RecipeSectionReducer.Action.recipes
          )) { childStore in
            let id = ViewStore(childStore, observe: \.id).state
            RecipeGridItemView(
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
                viewStore.send(.recipeSelected(id), animation: .default)
              }
              else {
                viewStore.send(.delegate(.recipeTapped(id)), animation: .default)
              }
            }
          }
        }
        .animation(.default, value: viewStore.recipes.count)
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
struct RecipeSectionView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      RecipeSectionView(
        store: .init(
          initialState: .init(title: "Recipes", recipes: .init(uniqueElements: Folder.shortMock.recipes)),
          reducer: RecipeSectionReducer.init
        ),
        isEditing: false
      )
      .padding(20)
    }
  }
}
