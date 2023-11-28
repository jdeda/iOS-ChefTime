import Tagged
import Foundation
import ComposableArchitecture
import SwiftUI


/// A simple enumeration representing if something didLoad, didNotLoad, or isLoading
@CasePathable
enum LoadStatus: Equatable {
  case didNotLoad
  case isLoading
  case didLoad
}

/// A simple enumeration representing a state of above or below.
@CasePathable
enum AboveBelow: Equatable {
  case above
  case below
}

/// Determines if and where the `TextField` has entered, either at the beginning or end of the new string.
/// Essentially serves as a proxy to accouting cursor position.
///
/// - Assumes that if the difference of the two strings where the new string is only different by a trailing new line,
/// then the user entered at the end of the string
/// - Assumes that if the difference of the two strings where the new string is only different by a leading new line,
/// then the user entered at the beginning of the string
///
/// Returns a DidEnter enumeration representing:
/// - didNotSatisfy - if the new value has not satisfied the parameters for a valid return
/// - beginning - if the value has satisfied the parameters for a valid return, and did so via the beginning
/// - end - if the value has satisfied the parameters for a valid return, and did so via the end
@CasePathable
enum DidEnter: Equatable {
  case didNotSatisfy
  case leading
  case trailing
  
  /// Returns a DidEnter value depending on the given strings and whether or not a newline was entered at the end
  /// 1. if leading newline, don't update name and insert above
  /// 2. else trailing newline, don't update name and focus to amount
  /// 3. else, update name
  static func didEnter(_ old: String, _ new: String) -> DidEnter {
    guard !old.isEmpty, !new.isEmpty
    else { return .didNotSatisfy }
    let originalNew = new
    
    // Check if leading
    var new = originalNew
    let firstNewCharacter = new.removeFirst()
    if old == new && firstNewCharacter.isNewline {
      return .leading
    }
    else {
      // Check if trailing
      var new = originalNew
      let lastNewCharacter = new.removeLast()
      if old == new && lastNewCharacter.isNewline {
        return .trailing
      }
    }
    return .didNotSatisfy
  }
}
