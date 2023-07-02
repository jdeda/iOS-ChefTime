import SwiftUI
//
//struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
//  func makeBody(configuration: Configuration) -> some View {
//    HStack(alignment: .top) {
//      configuration.label
//      Spacer()
//      Button {
//        withAnimation {
//          configuration.isExpanded.toggle()
//        }
//      } label: {
//        Image(systemName: "chevron.right")
//          .rotationEffect(configuration.isExpanded ? .degrees(90) : .degrees(0))
//          .animation(.linear(duration: 0.3), value: configuration.isExpanded)
//          .font(.caption)
//          .fontWeight(.bold)
//          .frame(maxWidth : 100, alignment: .trailing)
//          .padding([.bottom], 20)
//
//      }
//      .frame(maxWidth : 100, alignment: .trailing)
//      .padding([.bottom], 20)
//      .buttonStyle(.plain)
//      .border(.red)
//    }
//    .contentShape(Rectangle())
//    if configuration.isExpanded {
//      configuration.content
//        .disclosureGroupStyle(self)
//    }
//  }
//}


// TODO: Could make vertical height better
struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .center) {
      configuration.label
      Image(systemName: "chevron.right")
        .rotationEffect(configuration.isExpanded ? .degrees(90) : .degrees(0))
        .animation(.linear(duration: 0.3), value: configuration.isExpanded)
        .font(.caption)
        .fontWeight(.bold)
        .frame(maxWidth : 100, maxHeight: .infinity, alignment: .trailing)
        .buttonStyle(.plain)
        .onTapGesture {
          withAnimation {
            configuration.isExpanded.toggle()
          }
        }
    }
    .contentShape(Rectangle())
    if configuration.isExpanded {
      configuration.content
        .disclosureGroupStyle(self)
    }
  }
}
