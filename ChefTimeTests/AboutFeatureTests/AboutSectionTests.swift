import XCTest
import ComposableArchitecture
import Dependencies

@testable import ChefTime

//case binding(BindingAction<State>)
//case isExpandedButtonToggled
//case aboutSectionNameEdited(String)
//case aboutSectionDescriptionEdited(String)
//case keyboardDoneButtonTapped
//case delegate(DelegateAction)

@MainActor
final class AboutSectionTests: XCTestCase {
  
  func testAboutSectionNameEdited() async {
    let store = TestStore(
      initialState: AboutSectionReducer.State(
        id: .init(),
        aboutSection: .init(id: .init(), name: "foo", description: "nothing"),
        isExpanded: true,
        focusedField: .name
      ),
      reducer: AboutSectionReducer.init
    )
    
    await store.send(.aboutSectionNameEdited("foob")) {
      $0.aboutSection.name = "foob"
    }
    
    await store.send(.aboutSectionNameEdited("fooby")) {
      $0.aboutSection.name = "fooby"
    }
    
    await store.send(.aboutSectionNameEdited("foob")) {
      $0.aboutSection.name = "foob"
    }
    
    await store.send(.aboutSectionNameEdited("foo")) {
      $0.aboutSection.name = "foo"
    }
    
    await store.send(.aboutSectionNameEdited("foo"))
    
    // Pasting an empty name should leave the name as empty and nothing else.
    await store.send(.aboutSectionNameEdited("\n")) {
      $0.aboutSection.name = ""
    }
    
    // Clicking enter with nothing but whitespaces shouldn't trigger a keyboard dismiss.
    await store.send(.aboutSectionNameEdited("\n"))
    await store.send(.aboutSectionNameEdited("\n     "))
    await store.send(.aboutSectionNameEdited("   \n"))
    
    // But pressing enter on a name that is not whitespace with a description
    // that is not whitespace should just dismiss the keyboard.
    await store.send(.aboutSectionNameEdited("foobar")) {
      $0.aboutSection.name = "foobar"
    }
    await store.send(.aboutSectionNameEdited("foobar\n")) {
      $0.focusedField = nil
    }
    
    // But pressing enter on a name that is not whitespace with a description
    // that is just whitespace should focus onto the decsription.
    await store.send(.binding(.set(\.$focusedField, .name))) {
      $0.focusedField = .name
    }
    await store.send(.aboutSectionDescriptionEdited("")) {
      $0.aboutSection.description = ""
    }
    await store.send(.aboutSectionNameEdited("foobar\n")) {
      $0.focusedField = .description
    }
  }
  
  func testKeyboardDoneButtonTapped() async {
    let store = TestStore(
      initialState: AboutSectionReducer.State(
        id: .init(),
        aboutSection: .init(id: .init(), name: "foo", description: "nothing"),
        isExpanded: true,
        focusedField: .name
      ),
      reducer: AboutSectionReducer.init
    )
    
    await store.send(.keyboardDoneButtonTapped) {
      $0.focusedField = nil
    }
    
    await store.send(.binding(.set(\.$focusedField, .description))) {
      $0.focusedField = .description
    }
    
    await store.send(.keyboardDoneButtonTapped) {
      $0.focusedField = nil
    }
  }
  
  func testIsExpandedButtonToggled() async {
    let store = TestStore(
      initialState: AboutSectionReducer.State(
        id: .init(),
        aboutSection: .init(id: .init(), name: "foo", description: "nothing"),
        isExpanded: true,
        focusedField: .name
      ),
      reducer: AboutSectionReducer.init
    )
    
    XCTAssertTrue(store.state.isExpanded == true)
    
    await store.send(.binding(.set(\.$isExpanded, false))) {
      $0.isExpanded = false
      $0.focusedField = nil
    }
    
    await store.send(.binding(.set(\.$isExpanded, true))) {
      $0.isExpanded = true
    }
    
    await store.send(.binding(.set(\.$isExpanded, false))) {
      $0.isExpanded = false
    }
  }
}

