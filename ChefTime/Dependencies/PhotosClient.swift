import Dependencies
import Photos
import PhotosUI
import SwiftUI

struct PhotosClient: DependencyKey {
  var requestAuthorization: @Sendable () async -> PHAuthorizationStatus
  var getAuthorizationStatus: @Sendable () -> PHAuthorizationStatus
  var convertPhotoPickerItem: @Sendable (PhotosPickerItem) async -> Data?
  var convertPhotoPickerItems: @Sendable ([PhotosPickerItem]) async -> [Data]

  struct Failure: Equatable, Error {}
}

extension DependencyValues {
  var photos: PhotosClient {
    get { self[PhotosClient.self] }
    set { self[PhotosClient.self] = newValue }
  }
}

extension PhotosClient {
  static var liveValue = Self.live
//  static var previewValue = Self.preview
//  static var testValue = Self.test
}

extension PhotosClient {
  static var live: Self {
    return Self(
      requestAuthorization: {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      },
      getAuthorizationStatus: {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
      },
      convertPhotoPickerItem: { photosPickerItem in
        try? await photosPickerItem.loadTransferable(type: Data.self)
      },
      convertPhotoPickerItems: { photosPickerItems in
        await withTaskGroup(of: Data?.self, returning: [Data].self) { taskGroup in
          for item in photosPickerItems {
            taskGroup.addTask {
              try? await item.loadTransferable(type: Data.self)
            }
          }
          return await taskGroup.reduce(into: []) { partial, element in
            guard let element else { return }
            partial.append(element)
          }
        }
      }
    )
  }
}

extension PHAuthorizationStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .notDetermined:
      return "not-determined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .limited:
      return "limited"
    @unknown default:
      return "unkown"
    }
  }
}

