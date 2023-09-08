import SwiftUI
import ComposableArchitecture
import Foundation

// TODO: Fix swipe lag
struct ImageSliderView: View {
  let imageDatas: IdentifiedArrayOf<ImageData>
  @Binding var selection: ImageData.ID?
  @Environment(\.maxScreenWidth) var maxScreenWidth
  @Environment(\.imageSliderViewClipShape) private var clipShape
  
  var body: some View {
    TabView(selection: $selection) {
      ForEach(Array(zip(imageDatas.indices, imageDatas)), id: \.0) { index, imageData in
        imageData.image
          .square()
          .clipShape(clipShape.shape, style: clipShape.style)
          .tag(Optional(imageData.id))
      }
    }
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
    .tabViewStyle(PageTabViewStyle())
    .indexViewStyle(PageIndexViewStyle())
    .clipShape(clipShape.shape, style: clipShape.style)
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
      .clipShape2(AnyShape(RoundedRectangle(cornerRadius: 15)))
      .frame(width: 350, height: 350)
    }
  }
}

extension ImageSliderView {
  struct ClipShape: EnvironmentKey {
    static var defaultValue = Self(shape: AnyShape(Rectangle()), style: .init())
    let shape: AnyShape
    let style: FillStyle
  }
  
  func clipShape2(_ shape: AnyShape, _ style: FillStyle = .init()) -> some View {
    environment(\.imageSliderViewClipShape, ClipShape(shape: shape, style: style))
  }
}

private extension EnvironmentValues {
  var imageSliderViewClipShape: ImageSliderView.ClipShape {
    get { self[ImageSliderView.ClipShape.self] }
    set { self[ImageSliderView.ClipShape.self] = newValue }
  }
}
