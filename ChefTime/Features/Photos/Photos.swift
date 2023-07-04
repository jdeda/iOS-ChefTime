import SwiftUI
import ComposableArchitecture

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  let maxW = UIScreen.main.bounds.width * 0.85
  
  struct ViewState: Equatable {
    var photos: IdentifiedArrayOf<Recipe.ImageData>
    
    init(_ state: PhotosReducer.State) {
      self.photos = state.photos
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      if viewStore.photos.isEmpty {
          VStack {
            Image(systemName: "photo.stack")
              .resizable()
              .scaledToFit()
              .frame(width: 75, height: 75)
              .clipped()
              .foregroundColor(.secondary)
              .padding()
            Text("Add Images")
              .fontWeight(.bold) // TODO: To be or not to be bold...
              .foregroundColor(.secondary)
          }
        .frame(width: maxW, height: maxW)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .accentColor(.accentColor)
      }
      else {
        ImageSliderView(imageDatas: viewStore.photos)
      }
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
          initialState: .init(recipe: .empty),
          reducer: PhotosReducer.init
        ))
      }
      .padding()
    }
  }
}

