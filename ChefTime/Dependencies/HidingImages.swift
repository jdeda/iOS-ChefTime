import SwiftUI

extension Bool: EnvironmentKey {
  public static let defaultValue: Self = false
}

// Environment value used for hiding folder images inside a folder or folders view
extension EnvironmentValues {
  var isHidingImages: Bool {
    get { self[Bool.self] }
    set { self[Bool.self] = newValue }
  }
}
