import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FeatureView: View {
  let store: StoreOf<FeatureReducer>
  @FocusState private var focusedField: FeatureReducer.FocusField?
  
  var body: some View {
    WithViewStore(store) { viewStore in
      NavigationStack {
        Form {
          TextField("...", text: viewStore.binding(
            get: \.string1,
            send: { .string1Edited($0) }
          ))
          .focused($focusedField, equals: .string1)
          
          TextField("...", text: viewStore.binding(
            get: \.string2,
            send: { .string2Edited($0) }
          ))
          .focused($focusedField, equals: .string2)
          
        }
        .synchronize(viewStore.binding(\.$focusedField), $focusedField)
//        .bind(viewStore.binding(\.$focusedField), to: $focusedField)
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            Button {
              viewStore.send(.focusButtonTapped, animation: .default)
            } label: {
              Image(systemName: "checkmark")
            }
          }
          ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            Text("\(viewStore.focusedField?.string ?? "none")")
            Text(viewStore.updated)

            Spacer()
          }
        }
        .navigationTitle("Feature")
      }
    }
  }
}

// MARK: - Reducer
struct FeatureReducer: ReducerProtocol {
  struct State: Equatable {
    var string1 = ""
    var string2 = ""
    @BindingState var focusedField: FocusField? = nil {
      didSet {
        updated = "didSet"
      }
    }
    
    var updated: String = ""
  }
  
  enum Action: Equatable, BindableAction {
    case string1Edited(String)
    case string2Edited(String)
    case focusButtonTapped
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .string1Edited(newString):
        state.string1 = newString
        return .none
        
      case let .string2Edited(newString):
        state.string2 = newString
        return .none
        
      case .focusButtonTapped:
        switch state.focusedField {
        case .string1: state.focusedField = .string2
        case .string2: state.focusedField = .string1
        default: state.focusedField = .string1
        }
        return .none
        
      case .binding:
        return .none
      }
    }
    ._printChanges()
  }
}

extension FeatureReducer {
  enum FocusField: Hashable {
    case string1
    case string2
    
    var string: String {
      switch self {
      case .string1: return "string1"
      case .string2: return "string2"
      }
    }
  }
}

// MARK: - Preview
struct FeatureView_Previews: PreviewProvider {
  static var previews: some View {
    FeatureView(store: .init(
      initialState: .init(),
      reducer: FeatureReducer.init
    ))
  }
}

