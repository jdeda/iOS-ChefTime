import XCTest
import ComposableArchitecture

@MainActor
final class ChefTimeTests: XCTestCase {
  
  func test() async {
    var x = 1
    x += 1
    assert(x == 2)
  }
}
