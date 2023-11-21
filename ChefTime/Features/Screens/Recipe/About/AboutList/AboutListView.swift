import SwiftUI
import ComposableArchitecture

struct AboutListView: View {
  let store: StoreOf<AboutListReducer>
  @FocusState private var focusedField: AboutListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      if viewStore.aboutSections.isEmpty {
        VStack {
          HStack {
            Text("About")
              .textTitleStyle()
            Spacer()
          }
          HStack {
            TextField(
              "Untitled About Section",
              text: .constant(""),
              axis: .vertical
            )
            .textSubtitleStyle()
            Spacer()
            Image(systemName: "plus")
          }
          .foregroundColor(.secondary)
          .onTapGesture {
            viewStore.send(.addSectionButtonTapped, animation: .default)
          }
        }
      }
      else {
        DisclosureGroup(isExpanded: viewStore.$isExpanded) {
          ForEachStore(store.scope(state: \.aboutSections, action: { .aboutSections($0) })) { childStore in
            AboutSection(store: childStore)
              .contentShape(Rectangle())
              .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
              .accentColor(.accentColor)
            Divider()
              .padding([.vertical], 5)
          }
        }
        label : {
          Text("About")
            .textTitleStyle()
          Spacer()
        }
        .accentColor(.primary)
        .synchronize(viewStore.$focusedField, $focusedField)
        .disclosureGroupStyle(CustomDisclosureGroupStyle())
      }
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      AboutListView(store: .init(
        initialState: .init(
          recipeSections: Recipe.longMock.aboutSections
        ),
        reducer: AboutListReducer.init
      ))
      .padding()
    }
  }
}
