import SwiftUI

/// Simply a CustomDisclosureGroupStyle for better clicking ergonomics whenever the label is a textfield.
/// The style includes expansion operating from tapping a chevron icon, with haptic feed back and a brief debounce.
struct CustomDisclosureGroupStyle: DisclosureGroupStyle {
  @State var inFlight = false
  @State var task: Task<Void, Error>?
  let impactFeedback: UIImpactFeedbackGenerator = {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.prepare()
    return generator
  }()
  
  func makeBody(configuration: Configuration) -> some View {
    VStack {
      HStack(alignment: .center) {
        configuration.label
        Button {
          impactFeedback.impactOccurred()
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
            .frame(maxWidth : 60, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(maxWidth : 60, maxHeight: .infinity, alignment: .trailing)
      }
      .contentShape(Rectangle())
      .padding([.bottom], 5)
      
      if configuration.isExpanded {
        configuration.content
      }
    }
  }
}

/// Because we wrote our own disclosure group style, we lost the context menu transitions. To fix this,
/// we will have to create a custom view modifier for custom context menu logic, allowing a custom or default
/// previewForHighlightingMenuWithConfiguration and previewForDismissingMenuWithConfiguration (UIKit stuff).
/// The result is we will get back our context menu transitions.
/// Here's some resources I found to address this:
/// - https://www.fivestars.blog/articles/uicontextmenuinteraction/
/// - https://gist.github.com/SpectralDragon/e1c01388db09752eac790ae23f1d4587

