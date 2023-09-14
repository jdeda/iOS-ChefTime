import SwiftUI
import ComposableArchitecture

// MARK: - View
struct RecipeSectionView: View {
  let store: StoreOf<RecipeSectionReducer>
  let isEditing: Bool
  private let columns = Array(repeating: GridItem(spacing: 20, alignment: .top), count: 2)
  @Environment(\.isHidingFolderImages) private var isHidingFolderImages
  
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
            .frame(maxHeight: viewStore.isExpanded ? .infinity : 0.0)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .opacity(viewStore.isExpanded ? 1.0 : 0.0)
            .onTapGesture {
              if isEditing {
                viewStore.send(.recipeSelected(id), animation: .default)
              }
              else {
                viewStore.send(.delegate(.folderTapped(id)), animation: .default)
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

// MARK: - Reducer
struct RecipeSectionReducer: Reducer {
  struct State: Equatable {
    let title: String
    var recipes: IdentifiedArrayOf<RecipeGridItemReducer.State> = []
    @BindingState var isExpanded: Bool = true
    @BindingState var selection = Set<RecipeGridItemReducer.State.ID>()
  }
  
  enum Action: Equatable, BindableAction {
    case recipeSelected(RecipeGridItemReducer.State.ID)
    case recipes(RecipeGridItemReducer.State.ID, RecipeGridItemReducer.Action)
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .recipeSelected(id):
        if state.selection.contains(id) {
          state.selection.remove(id)
        }
        else {
          state.selection.insert(id)
        }
        
        return .none
        
      case let .recipes(id, .delegate(action)):
        switch action {
        case .move:
          break
        case .delete:
          state.recipes.remove(id: id)
          break
        }
        return .none
        
        
      case .recipes, .binding, .delegate:
        return .none
      }
    }
    .forEach(\.recipes, action: /Action.recipes) {
      RecipeGridItemReducer()
    }
    
  }
}

// MARK: - DelegateAction
extension RecipeSectionReducer {
  enum DelegateAction: Equatable {
    case folderTapped(RecipeGridItemReducer.State.ID)
  }
}

// MARK: - Preview
struct RecipeSectionView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      RecipeSectionView(
        store: .init(
          initialState: .init(title: "Recipes", recipes: .init(uniqueElements: Folder.shortMock.recipes.map {
            .init(id: .init(), recipe: $0)}
          )),
          reducer: RecipeSectionReducer.init
        ),
        isEditing: false
      )
      .padding(20)
    }
  }
}
