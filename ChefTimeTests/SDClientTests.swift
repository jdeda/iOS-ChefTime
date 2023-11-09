import XCTest
import ComposableArchitecture
import Dependencies
import SwiftData

@testable import ChefTime

@MainActor
final class SDClientTests: XCTestCase {
  
  func testFolderCRUD() async {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
  }
}

