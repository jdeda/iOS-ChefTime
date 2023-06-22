import SwiftUI
import ComposableArchitecture
import Tagged

struct StepsListView: View {
  let store: StoreOf<StepsListReducer>
  @State var isOn: Bool = false
  
  @State var isExpanded: Bool = true
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.binding(
        get: \.isExpanded,
        send: { _ in .isExpandedButtonToggled }
      )) {
        Toggle("Hide Images", isOn: $isOn)
          .font(.title3)
          .fontWeight(.bold)
        
        ForEachStore(store.scope(
          state: \.sections,
          action: StepsListReducer.Action.section
        )) { childStore in
          StepSectionView(store: childStore)
        }
        
        HStack {
          Text(" ")
          Spacer()
          Image(systemName: "plus")
            .font(.caption)
            .fontWeight(.bold)
            .onTapGesture {
//              viewStore.send(.addIngredientSectionButtonTapped, animation: .default)
            }
        }
        .foregroundColor(.secondary)
        
        Divider()
      } label: {
        Text("Steps")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
      .accentColor(.primary)
    }
  }
}

struct StepsListReducer: ReducerProtocol {
  struct State: Equatable {
    var isExpanded: Bool
    var sections: IdentifiedArrayOf<StepSectionReducer.State>
    
    init(recipe: Recipe, isExpanded: Bool) {
      self.sections = .init(uniqueElements: recipe.steps.map { section in
          .init(
            id: .init(),
            stepSection: section,
            isExpanded: true
          )
      })
      self.isExpanded = isExpanded
    }
  }
  
  enum Action: Equatable {
    case isExpandedButtonToggled
    case section(StepSectionReducer.State.ID, StepSectionReducer.Action)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .isExpandedButtonToggled:
        state.isExpanded.toggle()
        return .none
        
      case let .section(id, action):
        switch action {
        case let .delegate(action):
          return .none
        default:
          return .none
        }
      }
    }
    .forEach(\.sections, action: /Action.section) {
      StepSectionReducer()
    }
  }
}

struct StepsListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepsListView(store: .init(
          initialState: .init(recipe: Recipe.mock, isExpanded: true),
          reducer: StepsListReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
        .padding()
      }
    }
  }
}
