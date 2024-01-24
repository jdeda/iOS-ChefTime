import SwiftUI
import ComposableArchitecture

struct AboutListView: View {
  let store: StoreOf<AboutListReducer>
  @FocusState private var focusedField: AboutListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
//        LazyVStack {
          ForEachStore(store.scope(state: \.aboutSections, action: AboutListReducer.Action.aboutSections)) { childStore in
            if viewStore.aboutSections.count == 1 {
              AboutSectionNonGrouped(store: childStore)
                .contentShape(Rectangle())
                .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
                .accentColor(.accentColor)
            }
            else {
              AboutSection(store: childStore)
                .contentShape(Rectangle())
                .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
                .accentColor(.accentColor)
            }
            Divider()
              .padding([.vertical], 5)
          }
//        }
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
