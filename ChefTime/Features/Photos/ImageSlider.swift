import SwiftUI
import ComposableArchitecture

struct ImageSliderView: View {
  let imageDatas: IdentifiedArrayOf<Recipe.ImageData>
  let maxW = UIScreen.main.bounds.width * 0.85
  @State var isHovering: Bool = false

  var body: some View {
    VStack {
      TabView {
        ForEach(imageDatas) { imageData in
          if let data = imageData.imageData, let image = dataToImage(data) {
            image
              .resizable()
              .scaledToFill()
              .frame(width: maxW, height: maxW)
              .clipShape(RoundedRectangle(cornerRadius: 15))
          }
          else {
            Image(systemName: "photo")
              .resizable()
              .scaledToFill()
              .frame(width: maxW, height: maxW)
              .clipShape(RoundedRectangle(cornerRadius: 15))
          }
        }
      }
      .frame(width: maxW, height: maxW)
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .tabViewStyle(PageTabViewStyle())
      .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: isHovering ? .always : .never))
      .onHover { isHovering = $0 } // TODO: Make this work.
    }
  }
}

struct ImageSliderView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      ImageSliderView(imageDatas: Recipe.longMock.imageData)
    }
  }
}
