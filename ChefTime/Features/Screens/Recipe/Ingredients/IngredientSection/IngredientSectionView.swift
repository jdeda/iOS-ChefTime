import SwiftUI
import ComposableArchitecture

// TODO: - Bug - if focused on a row, then collapse, then click a row again, dupe buttons appear...
// but sometimes if you tap another row, the dupe goes away, this does not work all the time
// this is all happening probably because we didn't nil out the focus state
// TODO: Fix the weird textfield behavior with spaces

struct IngredientSection: View {
  let store: StoreOf<IngredientSectionReducer>
  @FocusState private var focusedField: IngredientSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
        ForEachStore(store.scope(state: \.ingredients, action: { .ingredients($0) })) { childStore in
          let id = ViewStore(childStore, observe: \.id).state
          IngredientView(store: childStore)
            .onTapGesture {
              viewStore.send(.rowTapped(id))
            }
            .focused($focusedField, equals: .row(id))
          if let lastId = viewStore.ingredients.last?.id, lastId != id {
            Divider()
          }
        }
      } label: {
        TextField(
          "Untitled Ingredient Section",
          text: viewStore.binding(
            get: \.ingredientSection.name,
            send: { .ingredientSectionNameEdited($0) }
          ),
          axis: .vertical
        )
        .focused($focusedField, equals: .name)
        .textSubtitleStyle()
        .toolbar {
          if viewStore.focusedField == .name {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button {
                viewStore.send(.ingredientSectionNameDoneButtonTapped)
              } label: {
                Text("done")
              }
            }
          }
        }
      }
      .synchronize(viewStore.$focusedField, $focusedField)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
      .contextMenu {
        Button {
          viewStore.send(.delegate(.insertSection(.above)), animation: .default)
        } label: {
          Text("Insert Section Above")
        }
        Button {
          viewStore.send(.delegate(.insertSection(.below)), animation: .default)
        } label: {
          Text("Insert Section Below")
        }
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      } preview: {
        IngredientSectionContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

private struct IngredientSectionContextMenuPreview: View {
  let state: IngredientSectionReducer.State
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      ForEach(state.ingredients.prefix(4)) { ingredient in
        IngredientContextMenuPreview(state: ingredient)
        Divider()
      }
    } label: {
      Text(!state.ingredientSection.name.isEmpty ? state.ingredientSection.name : "Untitled Ingredient Section")
        .lineLimit(2)
        .textSubtitleStyle()
    }
    .accentColor(.primary)
  }
}

// Represents the IngredientSection without a DisclosureGroup.
struct IngredientSectionNonGrouped: View {
  let store: StoreOf<IngredientSectionReducer>
  @FocusState private var focusedField: IngredientSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
        ForEachStore(store.scope(state: \.ingredients, action: { .ingredients($0) })) { childStore in
          let id = ViewStore(childStore, observe: \.id).state
          IngredientView(store: childStore)
            .onTapGesture {
              viewStore.send(.rowTapped(id))
            }
            .focused($focusedField, equals: .row(id))
          if let lastId = viewStore.ingredients.last?.id, lastId != id {
            Divider()
          }
        }
      .synchronize(viewStore.$focusedField, $focusedField)
      .accentColor(.primary)
      .contextMenu {
        Button {
          viewStore.send(.delegate(.insertSection(.above)), animation: .default)
        } label: {
          Text("Insert Section Above")
        }
        Button {
          viewStore.send(.delegate(.insertSection(.below)), animation: .default)
        } label: {
          Text("Insert Section Below")
        }
        Button(role: .destructive) {
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
        } label: {
          Text("Delete")
        }
      } preview: {
        ForEach(viewStore.ingredients.prefix(4)) { ingredient in
          IngredientContextMenuPreview(state: ingredient)
          Divider()
        }
        .accentColor(.primary)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      IngredientSection(store: .init(
        initialState: .init(
          ingredientSection: Recipe.longMock.ingredientSections.first!
        ),
        reducer: IngredientSectionReducer.init
      ))
      .padding()
    }
  }
}
