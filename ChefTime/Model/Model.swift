import Tagged
import Foundation
import ComposableArchitecture
import SwiftUI

/// A simple enumeration representing a state of above or below.
enum AboveBelow: Equatable {
  case above
  case below
}

/// Determines if and where the `TextField` has entered, either at the beginning or end of the new string.
/// Essentially serves as a proxy to accouting cursor position.
///
/// Assumes that if the difference of the two strings where the new string is only different by a trailing new line, then the user entered at the end of the string
/// Assumes that if the difference of the two strings where the new string is only different by a leading new line, then the user entered at the beginning of the string
/// Returns a DidEnter enumeration representing:
/// - didNotSatisfy - if the new value has not satisfied the parameters for a valid return
/// - beginning - if the value has satisfied the parameters for a valid return, and did so via the beginning
/// - end - if the value has satisfied the parameters for a valid return, and did so via the end
enum DidEnter: Equatable {
  case didNotSatisfy
  case leading
  case trailing
}

extension DidEnter {
  static func didEnter(_ old: String, _ new: String) -> DidEnter {
    guard !old.isEmpty, !new.isEmpty
    else { return .didNotSatisfy }
    
    let newSafe = new
    
    var new = newSafe
    let lastCharacter = new.removeLast()
    if old == new && lastCharacter.isNewline {
      return .trailing
    }
    else {
      var new = newSafe
      let firstCharacter = new.removeFirst()
      if old == new && firstCharacter.isNewline {
        return .leading
      }
    }
    return .didNotSatisfy
  }
}
