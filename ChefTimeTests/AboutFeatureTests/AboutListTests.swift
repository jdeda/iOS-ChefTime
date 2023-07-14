import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

@MainActor
final class AboutListTests: XCTestCase {
  
  func testBinding() async {
    let store = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: AboutListReducer.State(
          aboutSections: .init(uniqueElements: [
            .init(
              id: .init(rawValue: uuid()),
              aboutSection: .init(
                id: .init(rawValue: uuid()),
                name: "Bread",
                description: "Nothing better since sliced white bread!"),
              isExpanded: true,
              focusedField: .name
            )
          ]),
          isExpanded: true,
          focusedField: .row(.init(rawValue: UUID(0)))
        ),
        reducer: AboutListReducer.init
      ) {
        $0.uuid = .incrementing
      }
    }
    
    XCTAssertTrue(store.state.aboutSections.first!.id.uuidString == UUID(0).uuidString)
    XCTAssertTrue(store.state.aboutSections.first!.aboutSection.id.uuidString == UUID(1).uuidString)
    XCTAssertTrue(
      (/AboutListReducer.FocusField.row)
        .extract(from: store.state.focusedField)!.uuidString
      ==
      UUID(0).uuidString
    )
    
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = false
      $0.focusedField = nil
      $0.aboutSections[0].focusedField = nil
    }
    await store.send(.isExpandedButtonToggled) {
      $0.isExpanded = true
    }
  }
  
  func testAddSectionButtonTapped() async {
    let store = TestStore(
      initialState: AboutListReducer.State(aboutSections: [], isExpanded: true),
      reducer: AboutListReducer.init,
      withDependencies: {
        $0.uuid = .incrementing
      }
    )
    
    await store.send(.addSectionButtonTapped) {
      $0.aboutSections.append(.init(
        id: .init(rawValue: UUID(0)),
        aboutSection: .init(
          id: .init(rawValue: UUID(1)),
          name: "",
          description: ""
        ),
        isExpanded: true,
        focusedField: .name
      ))
      $0.focusedField = .row(.init(rawValue: UUID(0)))
    }
  }
  
  func testDelegateAddSection() async {
    let store = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: AboutListReducer.State(
          aboutSections: .init(uniqueElements: [
            .init(
              id: .init(rawValue: uuid()),
              aboutSection: .init(
                id: .init(rawValue: uuid()),
                name: "Bread",
                description: "Nothing better since sliced white bread!"),
              isExpanded: true,
              focusedField: .name
            )
          ]),
          isExpanded: true,
          focusedField: .row(.init(rawValue: UUID(0)))
        ),
        reducer: AboutListReducer.init
      ) {
        $0.uuid = .incrementing
      }
    }
    
    await store.send(.aboutSection(.init(rawValue: UUID(0)), .delegate(.insertSection(.below)))) {
      $0.aboutSections[0].focusedField = nil
      $0.aboutSections.append(.init(
        id: .init(rawValue: UUID(2)),
        aboutSection: .init(
          id: .init(rawValue: UUID(3)),
          name: "",
          description: ""
        ),
        isExpanded: true,
        focusedField: .name
      ))
      $0.focusedField = .row(.init(rawValue: UUID(2)))
    }
    
    await store.send(.aboutSection(.init(rawValue: UUID(2)), .delegate(.insertSection(.above)))) {
      $0.aboutSections[1].focusedField = nil
      $0.aboutSections.insert(
        .init(
          id: .init(rawValue: UUID(4)),
          aboutSection: .init(
            id: .init(rawValue: UUID(5)),
            name: "",
            description: ""
          ),
          isExpanded: true,
          focusedField: .name
        ),
        at: 1
      )
      $0.focusedField = .row(.init(rawValue: UUID(4)))
    }
  }
  
  func testDelegateDelete() async {
    let store = withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      return TestStore(
        initialState: AboutListReducer.State(
          aboutSections: .init(uniqueElements: [
            .init(
              id: .init(rawValue: uuid()),
              aboutSection: .init(
                id: .init(rawValue: uuid()),
                name: "Bread",
                description: "Nothing better since sliced white bread!"),
              isExpanded: true,
              focusedField: .name
            )
          ]),
          isExpanded: true,
          focusedField: .row(.init(rawValue: UUID(0)))
        ),
        reducer: AboutListReducer.init
      ) {
        $0.uuid = .incrementing
      }
    }
    
    await store.send(.aboutSection(.init(rawValue: UUID(0)), .delegate(.deleteSectionButtonTapped))) {
      $0.aboutSections.remove(id: .init(rawValue: UUID(0)))
      $0.focusedField = nil
    }
  }
}

