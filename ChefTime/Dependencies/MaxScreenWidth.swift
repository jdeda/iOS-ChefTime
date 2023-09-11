import SwiftUI

/// Represents maximum screen width and offsets.
struct MaxScreenWidth: EnvironmentKey {
  public static let defaultValue = Self.init(maxWidthPercentage: 0.9)
  
  /// Represents the width of the device screen.
  static let width: CGFloat = UIScreen.main.bounds.width
  
  /// Represents the maximum width percentage of the device screen.
  let maxWidthPercentage: Double
  
  /// Represents the maximum computed width of the device screen.
  var maxWidth: CGFloat {
    UIScreen.main.bounds.width * maxWidthPercentage
  }
  
  /// Represents the horizontal space between the device screen width
  /// and computed maximum computed width of the device screen
  var maxWidthHorizontalOffset: CGFloat {
    Self.width * (1.0 - maxWidthPercentage)
  }
}
extension EnvironmentValues {
  var maxScreenWidth: MaxScreenWidth {
    get { self[MaxScreenWidth.self] }
    set { self[MaxScreenWidth.self] = newValue }
  }
}
