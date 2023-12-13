import SwiftUI
import XCTestDynamicOverlay

struct RenameAlert: View {
  @State var name: String
  private let originalName: String
  @FocusState private var isTextFieldFocused: Bool
  
  init(name: String, submitName: @escaping (_: String) -> Void, cancel: @escaping () -> Void) {
    self.name = name
    self.originalName = name
    self.isTextFieldFocused = true
    self.submitName = submitName
    self.cancel = cancel
  }
  
  var submitName: (_ name: String) -> Void = unimplemented("RenameAlert.submitName")
  var cancel: () -> Void = unimplemented("RenameAlert.cancel")

  
  var body: some View {
        
    // MARK: - Runtime crash if textfield is wrapped in other views
    TextField("Name", text: $name)
      .onAppear { self.isTextFieldFocused = true } // MARK: - uncontrolled onAppear
      .focused($isTextFieldFocused)
    // ( •_•) This beautifully understandable block of code allows one to preselect the whole name (⁎❛ᴗ❛⁎ )
      .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
        if let textField = obj.object as? UITextField {
          textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
      }
    
    Button {
      self.name = originalName
      cancel()
    } label: {
      Text("Cancel")
        .fontWeight(.bold) // MARK: - Alert ignores these style modifiers...
    }
    
    Button {
      submitName(name)
    } label: {
      Text("Save")
        .fontWeight(.medium) // MARK: - Alert ignores these style modifiers...
    }
  }
}
