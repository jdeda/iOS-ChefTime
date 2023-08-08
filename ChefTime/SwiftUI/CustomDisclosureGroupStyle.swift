import SwiftUI

// Simply a CustomDisclosureGroupStyle for better clicking ergonomics, where the expand
// button is strictly the chevron icon, with a brief debounce for expansion.
struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  @State var inFlight = false
  @State var task: Task<Void, Never>?
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .center) {
      configuration.label
        .border(.red)
      

        Button {
          if inFlight {
            task?.cancel()
          }
          task = .init {
            inFlight = true
            do { try await Task.sleep(for: .milliseconds(250)) }
            catch {
              inFlight = false
              return
            }
            withAnimation {
              configuration.isExpanded.toggle()
            }
            inFlight = false
          }
        } label: {
          Image(systemName: "chevron.right")
            .rotationEffect(configuration.isExpanded ? .degrees(90) : .degrees(0))
            .animation(.linear(duration: 0.3), value: configuration.isExpanded)
            .font(.caption)
            .fontWeight(.bold)
        }
        .frame(maxWidth : 100, maxHeight: .infinity, alignment: .topTrailing)
        .buttonStyle(.plain)
              .border(.red)
      }
    .contentShape(Rectangle())
      
    let maxW: CGFloat = configuration.isExpanded ? .infinity : 0
    let a: Animation = .linear(duration: configuration.isExpanded ? 0.3 : 0.1)
    let o: Double = configuration.isExpanded ? 1.0 : 0.0
    configuration.content
      .animation(a, value: configuration.isExpanded)
      .frame(maxWidth: .infinity, maxHeight: maxW)
      .opacity(o)
      
      

  }
}

  // TODO: The alignment is fucked up.
