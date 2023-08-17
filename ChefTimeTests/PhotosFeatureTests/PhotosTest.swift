import XCTest
import _PhotosUI_SwiftUI
import ComposableArchitecture
import Dependencies

@testable import ChefTime
// TODO: Breakup tests into many different tests.
// TODO: Test photo operation consistency when other actions are sent in mid-flight

@MainActor
final class PhotosTests: XCTestCase {
  
  func testPhotoSelectionChanged() async throws {
    enum TestError: Error { case failure(String)  }
    
    let store = try withDependencies {
      $0.uuid = .incrementing
    } operation: {
      @Dependency(\.uuid) var uuid
      guard let data = UIImage(systemName: "square")?.pngData()
      else { throw TestError.failure("Failed to initialize data") }
      
      return TestStore(
        initialState: PhotosReducer.State(
          photos: .init(uniqueElements: [
            .init(id: .init(rawValue: UUID(0)), data: data)!,
            .init(id: .init(rawValue: UUID(1)), data: data)!,
            .init(id: .init(rawValue: UUID(2)), data: data)!
          ]
          ),
          selection: .init(.init(rawValue: UUID(0)))
        ),
        reducer: PhotosReducer.init,
        withDependencies: {
          $0.uuid = .incrementing
        }
      )
    }
    
    // User swipes right to select the second photo.
    await store.send(.photoSelectionChanged(.init(rawValue: UUID(1)))) {
      $0.selection = .init(rawValue: UUID(1))
    }
    
    // User swipes right to select the third and last photo.
    await store.send(.photoSelectionChanged(.init(rawValue: UUID(2)))) {
      $0.selection = .init(rawValue: UUID(2))
    }
    
    // User swipes left to select the second photo.
    await store.send(.photoSelectionChanged(.init(rawValue: UUID(1)))) {
      $0.selection = .init(rawValue: UUID(1))
    }
    
    // User swipes right to select the first photo.
    await store.send(.photoSelectionChanged(.init(rawValue: UUID(0)))) {
      $0.selection = .init(rawValue: UUID(0))
    }
  }
  
    /// Tests swiping, replace, add, delete, and dismiss.
    func testAllEditButtons() async {
      guard let imageData = try? XCTUnwrap(UIImage(systemName: "square")?.pngData())
      else {
        XCTFail("image1Data failed to init")
        return
      }
      guard let imageData2 = try? XCTUnwrap(UIImage(systemName: "square")?.pngData())
      else {
        XCTFail("image1Data failed to init")
        return
      }
  
  
      let clock = TestClock()
      let store = withDependencies {
        $0.uuid = .incrementing
      } operation: {
        @Dependency(\.uuid) var uuid
        return TestStore(
          initialState: PhotosReducer.State(
            photos: [],
            selection: nil
          ),
          reducer: PhotosReducer.init,
          withDependencies: {
            $0.uuid = .incrementing
            $0.photos.convertPhotoPickerItem = { item in
              try? await clock.sleep(for: .seconds(1))
              return item.itemIdentifier == "foo" ? imageData2 : imageData
            }
          }
        )
      }
  
      // For the sake of testing, it is impossible to actually create this item with data.
      // Our logic is we'd get an honest value with honest data that inits an honest image.
      // But because we cannot do that, we must loop-hole and rely on a dependency
      // to parse this item and just return whatever we want based on the test we want.
      let hypotheticallyHonestPhotosPickerItem: PhotosPickerItem = .init(itemIdentifier: "public.png")
  
      // This should popup the add sheet.
      // there shouldnt be any sleection and adding should fail because gthe selctiono is nil
      await store.send(.addButtonTapped) {
        $0.photoEditStatus = .addWhenEmpty
      }
  
      // Pick a somehow nil value, nothing should happen:
      await store.send(.photoPickerItem(nil))
  
      // Pick some image, based on our photo test version dependency
      let firstPhotoID: ImageData.ID = .init(rawValue: UUID(0))
      await store.send(.photoPickerItem(hypotheticallyHonestPhotosPickerItem))
      XCTAssertTrue(store.state.photoEditInFlight == true)
      await clock.advance(by: .seconds(1))
      await store.receive(
        .applyPhotoEdit(.addWhenEmpty, .init(id: firstPhotoID, data: imageData)!),
        timeout: .seconds(2)
      ) {
        $0.photos.append(.init(id: firstPhotoID, data: imageData)!)
        $0.selection = firstPhotoID
        $0.photoEditStatus = nil
        XCTAssertTrue($0.photoEditInFlight == false)
      }
  
      // Let's add another item.
      let secondPhotoID: ImageData.ID = .init(rawValue: UUID(1))
      await store.send(.addButtonTapped) {
        $0.photoEditStatus = .add(firstPhotoID)
        XCTAssertTrue($0.photoEditInFlight == true)
      }
      await store.send(.photoPickerItem(hypotheticallyHonestPhotosPickerItem))
      await clock.advance(by: .seconds(1))
      await store.receive(
        .applyPhotoEdit(.add(firstPhotoID), .init(id: secondPhotoID, data: imageData)!),
        timeout: .seconds(2)
      ) {
        $0.photos.insert(.init(id: secondPhotoID, data: imageData)!, at: 0)
        $0.selection = secondPhotoID
        $0.photoEditStatus = nil
        XCTAssertTrue($0.photoEditInFlight == false)
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: firstPhotoID) == 1)
      }
  
      // Lets swipe forward to our first image and add another.
      await store.send(.photoSelectionChanged(firstPhotoID)) {
        $0.selection = firstPhotoID
      }
  
      let thirdPhotoID: ImageData.ID = .init(rawValue: UUID(2))
      await store.send(.addButtonTapped) {
        $0.photoEditStatus = .add(firstPhotoID)
        XCTAssertTrue($0.photoEditInFlight == true)
      }
      await store.send(.photoPickerItem(hypotheticallyHonestPhotosPickerItem))
      await clock.advance(by: .seconds(1))
      await store.receive(
        .applyPhotoEdit(.add(firstPhotoID), .init(id: thirdPhotoID, data: imageData)!),
        timeout: .seconds(2)
      ) {
        $0.photos.insert(.init(id: thirdPhotoID, data: imageData)!, at: 1)
        $0.selection = thirdPhotoID
        $0.photoEditStatus = nil
        XCTAssertTrue($0.photoEditInFlight == false)
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 1)
        XCTAssertTrue($0.photos.index(id: firstPhotoID) == 2)
      }
  
      // With our new photos, lets swipe to the very first image and then all the way to the end and add another.
      await store.send(.photoSelectionChanged(secondPhotoID)) {
        $0.selection = secondPhotoID
        XCTAssertTrue(store.state.photos.index(id: secondPhotoID) == 0)
      }
      await store.send(.photoSelectionChanged(thirdPhotoID)) {
        $0.selection = thirdPhotoID
        XCTAssertTrue(store.state.photos.index(id: thirdPhotoID) == 1)
      }
      await store.send(.photoSelectionChanged(firstPhotoID)) {
        $0.selection = firstPhotoID
        XCTAssertTrue(store.state.photos.index(id: firstPhotoID) == 2)
      }
      let fourthPhotoID: ImageData.ID = .init(rawValue: UUID(3))
      await store.send(.addButtonTapped) {
        $0.photoEditStatus = .add(firstPhotoID)
        XCTAssertTrue($0.photoEditInFlight == true)
      }
      await store.send(.photoPickerItem(hypotheticallyHonestPhotosPickerItem))
      await clock.advance(by: .seconds(1))
      await store.receive(
        .applyPhotoEdit(.add(firstPhotoID), .init(id: fourthPhotoID, data: imageData)!),
        timeout: .seconds(2)
      ) {
        $0.photos.insert(.init(id: fourthPhotoID, data: imageData)!, at: 2)
        $0.selection = fourthPhotoID
        $0.photoEditStatus = nil
        XCTAssertTrue($0.photoEditInFlight == false)
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 1)
        XCTAssertTrue($0.photos.index(id: fourthPhotoID) == 2)
        XCTAssertTrue($0.photos.index(id: firstPhotoID) == 3)
      }
  
      // Now replace that image.
      let hypotheticallyHonestPhotosPickerItem2: PhotosPickerItem = .init(itemIdentifier: "foo")
      let fourthPhotoReplacementID: ImageData.ID = .init(rawValue: UUID(4))
      let fourthPhotoReplacement = ImageData(id: fourthPhotoReplacementID, data: imageData2)!
      await store.send(.replaceButtonTapped) {
        $0.photoEditStatus = .replace(fourthPhotoID)
        XCTAssertTrue($0.photoEditInFlight == true)
      }
      await store.send(.photoPickerItem(hypotheticallyHonestPhotosPickerItem2))
      await clock.advance(by: .seconds(1))
      await store.receive(
        .applyPhotoEdit(.replace(fourthPhotoID), fourthPhotoReplacement),
        timeout: .seconds(2)
      ) {
        let i = try XCTUnwrap($0.photos.index(id: fourthPhotoID))
        $0.photos.replaceSubrange(i...i, with: [fourthPhotoReplacement])
        $0.selection = fourthPhotoID
        $0.photoEditStatus = nil
        XCTAssertTrue($0.photoEditInFlight == false)
      }
  
      // Swipe the end of the in the list and replace that one.
      await store.send(.photoSelectionChanged(firstPhotoID)) {
        $0.selection = firstPhotoID
        XCTAssertTrue(store.state.photos.index(id: firstPhotoID) == 3)
      }
  
      let firstPhotoReplacementID: ImageData.ID = .init(rawValue: UUID(5))
      let firstPhotoReplacement = ImageData(id: firstPhotoReplacementID, data: imageData2)!
      await store.send(.replaceButtonTapped) {
        $0.photoEditStatus = .replace(firstPhotoID)
        XCTAssertTrue($0.photoEditInFlight == true)
      }
      await store.send(.photoPickerItem(hypotheticallyHonestPhotosPickerItem2))
      await clock.advance(by: .seconds(1))
      await store.receive(
        .applyPhotoEdit(.replace(firstPhotoID), .init(id: firstPhotoReplacementID, data: imageData2)!),
        timeout: .seconds(2)
      ) {
        let i = try XCTUnwrap($0.photos.index(id: firstPhotoID))
        $0.photos.replaceSubrange(i...i, with: [firstPhotoReplacement])
        $0.selection = firstPhotoID
        $0.photoEditStatus = nil
        XCTAssertTrue($0.photoEditInFlight == false)
      }
      // second(1), third(2), fourthReplacement(4), firstReplacement(5)
        
      // Swipe back and delete.
      await store.send(.photoSelectionChanged(fourthPhotoReplacementID)) {
        $0.selection = fourthPhotoReplacementID
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 1)
        XCTAssertTrue($0.photos.index(id: fourthPhotoReplacementID) == 2)
        XCTAssertTrue($0.photos.index(id: firstPhotoReplacementID) == 3)
      }
      await store.send(.deleteButtonTapped) {
        $0.selection = firstPhotoReplacementID
        $0.photos.remove(id: fourthPhotoReplacementID)
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 1)
        XCTAssertTrue($0.photos.index(id: firstPhotoReplacementID) == 2)
      }
  
      // Delete again.
      await store.send(.deleteButtonTapped) {
        $0.selection = thirdPhotoID
        $0.photos.remove(id: firstPhotoReplacementID)
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 1)
      }
  
      // Swipe back and delete.
      await store.send(.photoSelectionChanged(secondPhotoID)) {
        $0.selection = secondPhotoID
        XCTAssertTrue($0.photos.index(id: secondPhotoID) == 0)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 1)
      }
      await store.send(.deleteButtonTapped) {
        $0.selection = thirdPhotoID
        $0.photos.remove(id: secondPhotoID)
        XCTAssertTrue($0.photos.index(id: thirdPhotoID) == 0)
      }
  
      // Delete again.
      await store.send(.deleteButtonTapped) {
        $0.photos.remove(id: thirdPhotoID)
        $0.selection = nil
      }
  
      // Popup the sheet.
      await store.send(.addButtonTapped) {
        $0.photoEditStatus = .addWhenEmpty
      }
  
      // Use taps dismiss
      await store.send(.dismissPhotosPicker) {
        $0.photoEditStatus = nil
      }
    }
}
