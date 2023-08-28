import SwiftUI

extension Bool: EnvironmentKey {
  public static let defaultValue: Self = false
}

// Environment value used for hiding step images inside a recipe view.
extension EnvironmentValues {
  var isHidingStepImages: Bool {
    get { self[Bool.self] }
    set { self[Bool.self] = newValue }
  }
}

// Environment value used for hiding folder images inside a folder or folders view
extension EnvironmentValues {
  var isHidingFolderImages: Bool {
    get { self[Bool.self] }
    set { self[Bool.self] = newValue }
  }
}
