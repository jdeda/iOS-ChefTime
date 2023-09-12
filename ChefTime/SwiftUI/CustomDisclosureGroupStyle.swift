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
      
      configuration.content
        .frame(maxHeight: configuration.isExpanded ? .infinity : 0)
        .opacity(configuration.isExpanded ? 1.0 : 0)
    }
    .contentShape(ContentShapeKinds.contextMenuPreview, RoundedRectangle(cornerRadius: 5))
  }
}

// TODO: Maybe its just UIPreviewParameters().backgroundColor = .clear?????????
// let parameters = UIPreviewParameters()
// parameters.backgroundColor = .clear
// return UITargetedPreview(view: interaction.view!, parameters: parameters)


/// Because we wrote our own disclosure group style, we lost the context menu transitions. To fix this,
/// we will have to create a custom view modifier for custom context menu logic, allowing a custom or default
/// previewForHighlightingMenuWithConfiguration and previewForDismissingMenuWithConfiguration (UIKit stuff),
/// and some haptic feedback when we long hold. The result is we will get back our context menu transitions.
/// Here are some resources I found to address this:
/// - https://www.fivestars.blog/articles/uicontextmenuinteraction/
/// - https://gist.github.com/SpectralDragon/e1c01388db09752eac790ae23f1d4587

// MARK: - ContextMenuTransition ViewModifier
extension View {
  func customContextMenu<M: View, P: View, H: View, D: View>(
    @ViewBuilder menuItems: @escaping () -> M,
    @ViewBuilder preview: @escaping () -> P,
    @ViewBuilder highlight: @escaping () -> H = { EmptyView() },
    @ViewBuilder dimiss: @escaping () -> D = { EmptyView() }
  ) -> some View {
    self.modifier(PreviewContextViewModifier(menu: .init(
      menuItems: menuItems,
      preview: preview,
      highlight: highlight,
      dimiss: dimiss,
      actionProvider: { return UIMenu(title: "My Menu", children: $0) }
    )))
  }
}

struct PreviewContextViewModifier<M: View, P: View, H: View, D: View>: ViewModifier {
  let menu: PreviewContextMenu<M, P, H, D>
  @Environment(\.presentationMode) var mode
  
  @State var isActive: Bool = false
  
  func body(content: Content) -> some View {
    Group {
      if isActive {
        menu.preview
      } else {
        content.overlay(PreviewContextView(menu: menu, didCommitView: { self.isActive = true }))
      }
    }
  }
}

// MARK: - UIKit ContextMenu Implementation
struct PreviewContextMenu<M: View, P: View, H: View, D: View> {
  let menuItems: M
  let preview: P
  let highlight: H
  let dimiss: D
  let actionProvider: UIContextMenuActionProvider?
  
  init(
    @ViewBuilder menuItems: @escaping () -> M,
    @ViewBuilder preview: @escaping () -> P,
    @ViewBuilder highlight: @escaping () -> H = { EmptyView() },
    @ViewBuilder dimiss: @escaping () -> D = { EmptyView() },
    actionProvider: UIContextMenuActionProvider? = nil
  ) {
    self.menuItems = menuItems()
    self.preview = preview()
    self.highlight = highlight()
    self.dimiss = dimiss()
    self.actionProvider = actionProvider
  }
}

struct PreviewContextView<M: View, P: View, H: View, D: View>: UIViewRepresentable {
  
  let menu: PreviewContextMenu<M, P, H, D>
  let didCommitView: () -> Void
  
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    let menuInteraction = UIContextMenuInteraction(delegate: context.coordinator)
    view.addInteraction(menuInteraction)
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) { }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(menu: self.menu, didCommitView: self.didCommitView)
  }
  
  class Coordinator: NSObject, UIContextMenuInteractionDelegate {
    
    let menu: PreviewContextMenu<M, P, H, D>
    let didCommitView: () -> Void
    
    init(menu: PreviewContextMenu<M, P, H, D>, didCommitView: @escaping () -> Void) {
      self.menu = menu
      self.didCommitView = didCommitView
    }
    
    func contextMenuInteraction(
      _ interaction: UIContextMenuInteraction,
      configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
      return UIContextMenuConfiguration(
        identifier: nil,
        previewProvider: { () -> UIViewController? in
          UIHostingController(rootView: self.menu.preview)
        },
        actionProvider: self.menu.actionProvider
      )
    }
    
    func contextMenuInteraction(
      _ interaction: UIContextMenuInteraction,
      willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
      animator: UIContextMenuInteractionCommitAnimating
    ) {
      animator.addCompletion(self.didCommitView)
    }
    
    func contextMenuInteraction(
      _ interaction: UIContextMenuInteraction,
      previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      return UITargetedPreview(view: interaction.view!, parameters: parameters)
      // TODO: How do I inject my own view here
    }
    
    func contextMenuInteraction(
      _ interaction: UIContextMenuInteraction,
      previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      return UITargetedPreview(view: interaction.view!, parameters: parameters)
      // TODO: How do I inject my own view here
    }
  }
}
