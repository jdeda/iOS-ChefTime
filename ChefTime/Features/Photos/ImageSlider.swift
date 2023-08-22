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
      ForEach(imageDatas) { imageData in
        imageData.image
          .resizable()
          .scaledToFill()
          .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .tag(Optional(imageData.id))
      }
    }
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
    .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
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
    }
  }
}
