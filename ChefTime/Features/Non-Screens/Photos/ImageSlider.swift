import SwiftUI
import ComposableArchitecture
import Foundation
import Log4swift

// TODO: Fix swipe lag
struct ImageSliderView: View {
    let imageDatas: IdentifiedArrayOf<ImageData>
    @Binding var selection: ImageData.ID?

    var body: some View {
        let _ = Self._printChanges()
        Log4swift[Self.self].info("")

        // DEDA DEBUG
        // ignoring the selection for now
        return TabView {
            ForEach(Array(zip(imageDatas.indices, imageDatas)), id: \.0) { index, imageData in
                imageData.image
                    .square()
                    .tag(Optional(imageData.id))
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle())
        .clipShape((RoundedRectangle(cornerRadius: 15)))
        .opacity(!imageDatas.isEmpty ? 1.0 : 0.0 )
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


private struct _ImageSliderPreview: View {
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


#Preview {
    ScrollView {
        _ImageSliderPreview()
    }
}
