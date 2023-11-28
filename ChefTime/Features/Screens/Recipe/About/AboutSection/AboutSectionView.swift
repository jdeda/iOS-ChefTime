import SwiftUI
import ComposableArchitecture

struct AboutSection: View {
  let store: StoreOf<AboutSectionReducer>
  @FocusState private var focusedField: AboutSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
        TextField("...", text: viewStore.$aboutSection.description, axis: .vertical)
          .focused($focusedField, equals: .description)
          .accentColor(.accentColor)
          .autocapitalization(.none)
          .autocorrectionDisabled()
          .toolbar {
            if viewStore.focusedField == .description {
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
      } label: {
        TextField(
          "Untitled About Section",
          text: viewStore.binding(
            get: \.aboutSection.name,
            send: { .aboutSectionNameEdited($0) }
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
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .easeIn(duration: 2.5))
        } label: {
          Text("Delete")
        }
      } preview: {
        AboutSectionContextMenuPreview(state: viewStore.state)
          .frame(width: 200)
          .padding()
      }
    }
  }
}

private struct AboutSectionContextMenuPreview: View {
  let state: AboutSectionReducer.State
  
  var body: some View {
    DisclosureGroup(isExpanded: .constant(state.isExpanded)) {
      Text(!state.aboutSection.description.isEmpty ? state.aboutSection.description : "...")
        .lineLimit(4)
        .autocapitalization(.none)
        .autocorrectionDisabled()
    } label: {
      Text(!state.aboutSection.name.isEmpty ? state.aboutSection.name : "...")
        .lineLimit(2)
        .textSubtitleStyle()
    }
    .accentColor(.primary)
  }
}

// Represents the AboutSection without a DisclosureGroup.
struct AboutSectionNonGrouped: View {
  let store: StoreOf<AboutSectionReducer>
  @FocusState private var focusedField: AboutSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      TextField("...", text: viewStore.$aboutSection.description, axis: .vertical)
        .focused($focusedField, equals: .description)
        .accentColor(.accentColor)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .toolbar {
          if viewStore.focusedField == .description {
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
            viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .easeIn(duration: 2.5))
          } label: {
            Text("Delete")
          }
        } preview: {
          let d = viewStore.aboutSection.description
          Text(!d.isEmpty ? d : "...")
            .lineLimit(4)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .frame(width: 200)
            .padding()
        }
    }
  }
}


#Preview {
  NavigationStack {
    ScrollView {
      AboutSection(store: .init(
        initialState: .init(
          aboutSection: Recipe.longMock.aboutSections.first!
        ),
        reducer: AboutSectionReducer.init
      ))
      .padding()
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      AboutSection(store: .init(
        initialState: .init(
          aboutSection: .init(id: .init(), name: "", description: "")
        ),
        reducer: AboutSectionReducer.init
      ))
      .padding()
    }
  }
}
