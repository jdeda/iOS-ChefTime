import SwiftUI

// Simply a CustomDisclosureGroupStyle for better clicking ergonomics, where the expand
// button is strictly the chevron icon, with a brief debounce for expansion.
struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  @State var inFlight = false
  @State var task: Task<Void, Error>?
  
  func makeBody(configuration: Configuration) -> some View {
    VStack {
      HStack(alignment: .center) {
        configuration.label
        Button {
          if inFlight {
            task?.cancel()
          }
          task = .init {
            @MainActor func setInFlight() {
              inFlight = true
            }
            @MainActor func toggleExpanded() {
              withAnimation {
                configuration.isExpanded.toggle()
                inFlight = false
              }
            }
            
            await setInFlight()
            try await Task.sleep(for: .milliseconds(250))
            await toggleExpanded()
          }
        } label: {
          Image(systemName: "chevron.right")
            .rotationEffect(configuration.isExpanded ? .degrees(90) : .degrees(0))
            .animation(.linear(duration: 0.3), value: configuration.isExpanded)
            .font(.caption)
            .fontWeight(.bold)
            .frame(maxWidth : 40, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(maxWidth : 50, maxHeight: .infinity, alignment: .trailing)
      }
      .contentShape(Rectangle())
      
      if configuration.isExpanded {
        configuration.content
      }
    }
  }
}
