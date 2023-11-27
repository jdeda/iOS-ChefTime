import SwiftUI

private struct NavigationTitleStyleTextModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.largeTitle)
      .fontWeight(.bold)
      .foregroundColor(.primary)
  }
}
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
  func textNavigationTitleStyle() -> some View {
    self.modifier(NavigationTitleStyleTextModifier())
  }
  func textTitleStyle() -> some View {
    self.modifier(TitleStyleTextModifier())
  }
  func textSubtitleStyle() -> some View {
    self.modifier(SubTitleStyleTextModifier())
  }
}
