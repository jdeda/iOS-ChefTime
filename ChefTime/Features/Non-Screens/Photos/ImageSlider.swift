import SwiftUI
import ComposableArchitecture
import Foundation

// TODO: Fix swipe lag
struct ImageSliderView: View {
  let imageDatas: IdentifiedArrayOf<ImageData>
  @Binding var selection: ImageData.ID?
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    TabView(selection: $selection) {
      ForEach(Array(zip(imageDatas.indices, imageDatas)), id: \.0) { index, imageData in
        imageData.image
          .square()
          .clipShape((RoundedRectangle(cornerRadius: 15)))
          .tag(Optional(imageData.id))
      }
    }
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
    .clipShape((RoundedRectangle(cornerRadius: 15)))
  }
}

private extension Image {
  func square() -> some View {
    Rectangle()
      .fill(.clear)
      .aspectRatio(1, contentMode: .fit)
      .overlay(
        self
          .resizable()
          .scaledToFill()
      )
      .clipShape(Rectangle())
  }
}


struct ImageSliderView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      MasterView()
    }
  }
  
  struct MasterView: View {
    @State var imageDatas: IdentifiedArrayOf<ImageData> = Recipe.longMock.imageData
    @State var selection: ImageData.ID? = nil
    var body: some View {
      ImageSliderView(
        imageDatas: imageDatas,
        selection: $selection
      )
      .frame(width: 350, height: 350)
    }
  }
}
