import SwiftUI
import ComposableArchitecture

struct ImageSliderView: View {
  let imageDatas: IdentifiedArrayOf<Recipe.ImageData>
  let maxW = UIScreen.main.bounds.width * 0.85

  var body: some View {
    VStack {
      TabView {
        ForEach(imageDatas) { imageData in
          if let data = imageData.imageData, let image = dataToImage(data) {
            image
              .resizable()
              .scaledToFill()
          }
          else {
            Image(systemName: "photo")
              .resizable()
              .scaledToFill()
          }
        }
      }
      .tabViewStyle(PageTabViewStyle())
      .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
      .frame(width: maxW, height: maxW)
      .clipShape(RoundedRectangle(cornerRadius: 15))
    }
  }
}

struct ImageSliderView_Previews: PreviewProvider {
  static var previews: some View {
    ImageSliderView(imageDatas: Recipe.mock.imageData)
  }
}
