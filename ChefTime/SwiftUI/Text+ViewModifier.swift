import SwiftUI

private struct TitleStyleTextModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.title)
      .fontWeight(.bold)
      .foregroundColor(.primary)
  }
}

private struct SubTitleStyleTextModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.title3)
      .fontWeight(.bold)
      .foregroundColor(.primary)
      .accentColor(.accentColor)
      .frame(alignment: .leading)
      .multilineTextAlignment(.leading)
      .lineLimit(.max)
      .autocapitalization(.none)
      .disableAutocorrection(true)
  }
}

extension View {
  func textTitleStyle() -> some View {
    self.modifier(TitleStyleTextModifier())
  }
  func textSubtitleStyle() -> some View {
    self.modifier(SubTitleStyleTextModifier())
  }
}
