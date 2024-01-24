import SwiftUI
import ComposableArchitecture

// The ONLY way, to make this shit work is as follows:
/// 1. Every single TextField, will convert into Text that looks like a TextField.
///   - if empty, foregroundStyle should be secondary else primary
///   - align to leading
/// 2. Every single section, if u tap the description, drill down into section view focused on that element, title, same thing
/// - destination reducer refactoring
/// - when back button tapped, boom
/// 3. ImageSlider -- somehow get around the binding because it destroys everything like insanity
/// 4. Fix some weird accent colors on the alerts
/// 5. Fix mock data smothered chicken top picture and about section
/// 6. Fix mock data launch to work only once (very first launch, or maybe just leave it)
/// 7. Dry run empty elements? Eh
/// 8. Ask photos persmissions? Eh
/// 9. Get proper version on app store submission
/// 10. AppStore submitted
/// 11. Fix resume and portfolio website
struct AboutSection: View {
  let store: StoreOf<AboutSectionReducer>
  @FocusState private var focusedField: AboutSectionReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
        TextField(
          "...",
          text: viewStore.binding(
            get: \.aboutSection.description,
            send: { .aboutSectionDescriptionEdited($0) }
          ),
          axis: .vertical
        )
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
          viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
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
      TextField(
        "...",
        text: viewStore.binding(
          get: \.aboutSection.description,
          send: { .aboutSectionDescriptionEdited($0) }
        ),
        axis: .vertical
      )
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
            viewStore.send(.delegate(.deleteSectionButtonTapped), animation: .default)
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
