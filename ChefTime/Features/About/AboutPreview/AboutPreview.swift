import SwiftUI
import ComposableArchitecture
import Tagged

struct AboutPreviewReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var section: Recipe.AboutSection
    @BindingState var isExpanded: Bool
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerProtocolOf<Self> {
    BindingReducer()
  }
}
struct AboutPreview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        AboutPreview(store: .init(
          initialState: .init(
            id: .init(),
            section: Recipe.longMock.aboutSections.first!,
            isExpanded: true
          ),
          reducer: AboutPreviewReducer.init
        ))
      }
      .padding()
    }
  }
}
