import SwiftUI
import ComposableArchitecture

struct AboutView: View {
  let store: StoreOf<AboutReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(\.$isExpanded)) {
        TextField(
          "...",
          text: viewStore.binding(\.$description),
          axis: .vertical
        )
        .accentColor(.accentColor)
      } label: {
        Text("About")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .accentColor(.primary)
    }
  }
}

struct AboutReducer: ReducerProtocol {
  struct State: Equatable {
    @BindingState var isExpanded: Bool
    @BindingState var description: String
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
          initialState: .init(isExpanded: true, description: Recipe.mock.about),
          reducer: AboutReducer.init
        ))
      }
      .padding()
    }
  }
}


//import SwiftUI
//import ComposableArchitecture
//
//struct AboutView: View {
//  let store: StoreOf<AboutReducer>
//
//  struct ViewState: Equatable {
//    var isExpanded: Bool
//    var description: String
//
//    init(_ state: AboutReducer.State) {
//      self.isExpanded = state.isExpanded
//      self.description = state.description
//    }
//  }
//
//  var body: some View {
//    WithViewStore(store, observe: ViewState.init) { viewStore in
//      DisclosureGroup(isExpanded: viewStore.binding(
//        get: { $0.isExpanded },
//        send: { _ in .isExpandedButtonTapped }
//      )) {
//        TextField(
//          "...",
//          text: viewStore.binding(
//            get: { $0.description },
//            send: { .descriptionEdited($0) }
//          ),
//          axis: .vertical
//        )
//        .accentColor(.accentColor)
//      } label: {
//        Text("About")
//          .font(.title)
//          .fontWeight(.bold)
//          .foregroundColor(.primary)
//
//      }
//      .accentColor(.primary)
//    }
//  }
//}
//
//struct AboutReducer: ReducerProtocol {
//  struct State: Equatable {
//    var isExpanded: Bool
//    var description: String
//  }
//
//  enum Action: Equatable {
//    case isExpandedButtonTapped
//    case descriptionEdited(String)
//  }
//
//  var body: some ReducerProtocolOf<Self> {
//    Reduce { state, action in
//      switch action {
//      case .isExpandedButtonTapped:
//        state.isExpanded.toggle()
//        return .none
//
//      case let .descriptionEdited(newDescription):
//        state.description = newDescription
//        return .none
//      }
//    }
//  }
//}
//
//struct AboutView_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationStack {
//      ScrollView {
//        AboutView(store: .init(
//          initialState: .init(isExpanded: true, description: Recipe.mock.notes),
//          reducer: AboutReducer.init
//        ))
//      }
//      .padding()
//    }
//  }
//}
