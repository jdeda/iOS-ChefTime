import SwiftUI

struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
      Spacer()
      Button {
        withAnimation {
          configuration.isExpanded.toggle()
        }
      } label: {
        Image(systemName: "chevron.right")
          .rotationEffect(configuration.isExpanded ? .degrees(90) : .degrees(0))
          .animation(.linear(duration: 0.3), value: configuration.isExpanded)
          .font(.caption)
          .fontWeight(.bold)
      }
      .frame(maxWidth : 50, maxHeight: .infinity, alignment: .trailing)
      .buttonStyle(.plain)
    }
    .contentShape(Rectangle())
    if configuration.isExpanded {
      configuration.content
        .disclosureGroupStyle(self)
    }
  }
}
