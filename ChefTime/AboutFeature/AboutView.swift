import SwiftUI
import ComposableArchitecture
import Tagged

struct AboutView: View {
  let store: StoreOf<AboutReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(\.$isExpanded)) {
        TextField(
          "...",
          text: viewStore.binding(\.$section.description),
          axis: .vertical
        )
        .accentColor(.accentColor)
      } label: {
        TextField(
          "Untitled Section",
          text: viewStore.binding(\.$section.name),
          axis: .vertical

        )
        .font(.title3)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .accentColor(.accentColor)
        .frame(alignment: .leading)
        .multilineTextAlignment(.leading)
      }
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
    }
  }
}

struct AboutReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    @BindingState var section: Recipe.AboutSection
    @BindingState var isExpanded: Bool
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
  }
}
struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        AboutView(store: .init(
          initialState: .init(
            id: .init(),
            section: Recipe.mock.aboutSections.first!,
            isExpanded: true
          ),
          reducer: AboutReducer.init
        ))
      }
      .padding()
    }
  }
}
