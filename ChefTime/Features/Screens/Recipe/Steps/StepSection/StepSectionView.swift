import SwiftUI
import ComposableArchitecture

// TODO: - Bug - if focused on a row, then collapse, then click a row again, dupe buttons appear...
// but sometimes if you tap another row, the dupe goes away, this does not work all the time
// this is all happening probably because we didn't nil out the focus state

struct StepSection: View {
  let store: StoreOf<StepSectionReducer>
  @FocusState private var focusedField: StepSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
//        LazyVStack {
          ForEachStore(store.scope(state: \.steps, action: StepSectionReducer.Action.steps)) { childStore in
            // TODO: Move this into reducer and test.
            let id = ViewStore(childStore, observe: \.id).state
            let index = viewStore.steps.index(id:id) ?? 0
            StepView(store: childStore, index: index)
              .contextMenu {
                Button {
                  viewStore.send(.stepInsertButtonTapped(.above, ViewStore(childStore, observe: \.id).state), animation: .default)
                } label: {
                  Text("Insert Step Above")
                }
                Button {
                  viewStore.send(.stepInsertButtonTapped(.below, ViewStore(childStore, observe: \.id).state), animation: .default)
                } label: {
                  Text("Insert Step Below")
                }
                Button(role: .destructive) {
                  viewStore.send(.stepDeleteButtonTapped(ViewStore(childStore, observe: \.id).state), animation: .default)
                } label: {
                  Text("Delete")
                }
              } preview: {
                StepContextMenuPreview(state: ViewStore(childStore, observe: { $0 }).state, index: index)
                  .frame(width: 200)
                  .padding()
              }
              .accentColor(.accentColor)
            if let lastId = viewStore.steps.last?.id, lastId != id {
              Divider()
            }
          }
//        }
      } label: {
        TextField(
          "Untitled About Section",
          text: viewStore.binding(
            get: \.stepSection.name,
            send: { .stepSectionNameEdited($0) }
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
                viewStore.send(.keyboardDoneButtonTapped)
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
        StepSectionContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

private struct StepSectionContextMenuPreview: View {
  let state: StepSectionReducer.State
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      ForEach(state.steps.prefix(4)) { step in
        let index = state.steps.index(id: step.id) ?? 0
        StepContextMenuPreview(state: step, index: index)
        Divider() // TODO: Dont render last divier
      }
    } label: {
      TextField("Untitled About Section", text: .constant(state.stepSection.name))
        .textSubtitleStyle()
        .lineLimit(2)
        .disabled(true)
    }
    .accentColor(.primary)
  }
}

// Represents the StepSection without a DisclosureGroup.
struct StepSectionNonGrouped: View {
  let store: StoreOf<StepSectionReducer>
  @FocusState private var focusedField: StepSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ForEachStore(store.scope(state: \.steps, action: StepSectionReducer.Action.steps)) { childStore in
        // TODO: Move this into reducer and test.
        let id = ViewStore(childStore, observe: \.id).state
        let index = viewStore.steps.index(id:id) ?? 0
        StepView(store: childStore, index: index)
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
            Button {
              viewStore.send(.stepInsertButtonTapped(.above, ViewStore(childStore, observe: \.id).state), animation: .default)
            } label: {
              Text("Insert Step Above")
            }
            Button {
              viewStore.send(.stepInsertButtonTapped(.below, ViewStore(childStore, observe: \.id).state), animation: .default)
            } label: {
              Text("Insert Step Below")
            }
            Button(role: .destructive) {
              viewStore.send(.stepDeleteButtonTapped(ViewStore(childStore, observe: \.id).state), animation: .default)
            } label: {
              Text("Delete")
            }
          } preview: {
            StepContextMenuPreview(state: ViewStore(childStore, observe: { $0 }).state, index: index)
              .frame(width: 200)
              .padding()
          }
          .accentColor(.accentColor)
        if let lastId = viewStore.steps.last?.id, lastId != id {
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
        ForEach(viewStore.steps.prefix(4)) { step in
          let index = viewStore.steps.index(id: step.id) ?? 0
          StepContextMenuPreview(state: step, index: index)
          Divider() // TODO: Dont render last divier
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
      StepSection(store: .init(
        initialState: .init(
          stepSection: Recipe.longMock.stepSections.first!
        ),
        reducer: StepSectionReducer.init
      ))
      .padding()
    }
  }
}
