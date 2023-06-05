import SwiftUI

struct Collapsible<Content: View>: View {
  @State private var collapsed: Bool
  @State var label: () -> Text
  @State var content: () -> Content
  
  init(
    collapsed: Bool = true,
    @ViewBuilder label: @escaping () -> Text,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.collapsed = collapsed
    self.label = label
    self.content = content
  }
  
  
  var body: some View {
    VStack {
      Button(
        action: {
          withAnimation(.easeOut) {
            self.collapsed.toggle()
          }
        },
        label: {
          HStack {
            self.label()
            Spacer()
            Image(systemName: self.collapsed ? "chevron.down" : "chevron.up")
          }
          .padding(.bottom, 1)
          .background(Color.white.opacity(0.01))
        }
      )
      .buttonStyle(PlainButtonStyle())
      
      VStack {
        self.content()
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
      .clipped()
      .transition(.slide)
    }
  }
}
