import SwiftUI

// Simply a CustomDisclosureGroupStyle for better clicking ergonomics, where the expand
// button is strictly the chevron icon, with a brief debounce for expansion.
struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  @State var inFlight = false
  @State var task: Task<Void, Never>?
  func makeBody(configuration: Configuration) -> some View {
    LazyVStack {
      HStack(alignment: .center) {
        configuration.label
        Button {
          if inFlight {
            task?.cancel()
          }
          task = .init { @MainActor in 
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
      }
      .contentShape(Rectangle())
      
      if configuration.isExpanded {
        configuration.content
          .disclosureGroupStyle(self)
      }
    }
  }
}

// TODO: The alignment is fucked up.
