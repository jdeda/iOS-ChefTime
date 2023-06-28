import SwiftUI
import ComposableArchitecture

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  
  struct ViewState: Equatable {
    var photos: IdentifiedArrayOf<Recipe.ImageData>
    
    init(_ state: PhotosReducer.State) {
      self.photos = state.photos
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ImageSliderView(imageDatas: viewStore.photos)
    }
  }
}

// MARK: - Reducer
struct PhotosReducer: ReducerProtocol {
  struct State: Equatable {
    var photos: IdentifiedArrayOf<Recipe.ImageData>
    
    init(recipe: Recipe) {
      self.photos = recipe.imageData
    }
  }
  
  enum Action: Equatable {
    
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      }
    }
  }
}

// MARK: - Preview
struct PhotosView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        PhotosView(store: .init(
          initialState: .init(recipe: .longMock),
          reducer: PhotosReducer.init
        ))
      }
      .padding()
    }
  }
}

