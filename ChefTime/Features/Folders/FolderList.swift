import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FolderListView: View {
  let store: StoreOf<FolderListReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Text("FolderListView")
    }
  }
}

// MARK: - Reducer
struct FolderListReducer: Reducer {
  struct State: Equatable {
    
  }
  
  enum Action: Equatable {
    
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      }
    }
  }
}

// MARK: - Preview
struct FolderListView_Previews: PreviewProvider {
  static var previews: some View {
    FolderListView(store: .init(
      initialState: .init(),
      reducer: FolderListReducer.init
    ))
  }
}
