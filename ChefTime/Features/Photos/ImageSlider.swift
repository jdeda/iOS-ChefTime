import SwiftUI
import ComposableArchitecture
import Foundation

// TODO: Fix swipe lag
struct ImageSliderView: View {
  let maxW = UIScreen.main.bounds.width * 0.85
  let imageDatas: IdentifiedArrayOf<Recipe.ImageData>
  @Binding var selection: Recipe.ImageData.ID?
  
  var body: some View {
    TabView(selection: $selection) {
      ForEach(imageDatas) { imageData in
        dataToImage(imageData.imageData!)!
          .resizable()
          .scaledToFill()
          .frame(width: maxW, height: maxW)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .tag(Optional(imageData.id))
      }
    }
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
    .frame(width: maxW, height: maxW)
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
    @State var imageDatas: IdentifiedArrayOf<Recipe.ImageData> = Recipe.longMock.imageData
    @State var selection: Recipe.ImageData.ID? = nil
    var body: some View {
      ImageSliderView(
        imageDatas: imageDatas,
        selection: $selection
      )
    }
  }
}
