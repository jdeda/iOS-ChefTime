import SwiftUI
import ComposableArchitecture

struct StepListView: View {
  let store: StoreOf<StepListReducer>
  @FocusState private var focusedField: StepListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        DisclosureGroup(isExpanded: viewStore.$isExpanded) {
//          LazyVStack {
            ForEachStore(store.scope(state: \.stepSections, action: StepListReducer.Action.stepSections)) { childStore in
              if viewStore.stepSections.count == 1 {
                StepSectionNonGrouped(store: childStore)
                  .contentShape(Rectangle())
                  .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
                  .accentColor(.accentColor)
              }
              else {
                StepSection(store: childStore)
                  .contentShape(Rectangle())
                  .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
                  .accentColor(.accentColor)
              }
              Divider()
                .padding(.bottom, 5)
            }
//          }
        }
        label : {
          Text("Steps")
            .textTitleStyle()
          Spacer()
        }
        .accentColor(.primary)
        .disclosureGroupStyle(CustomDisclosureGroupStyle())
      }
      .synchronize(viewStore.$focusedField, $focusedField)
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      StepListView(store: .init(
        initialState: .init(
          recipeSections: Recipe.longMock.stepSections
        ),
        reducer: StepListReducer.init
      ))
      .padding()
    }
  }
}
