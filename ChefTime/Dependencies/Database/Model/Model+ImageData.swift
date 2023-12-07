import Tagged
import Foundation
import SwiftUI

struct SDData: Equatable, Codable, Identifiable {
  let id: UUID
  let data: Data
  var positionPriority: Int?
  
  init(id: ID, data: Data, positionPriority: Int? = nil) {
    self.id = id
    self.data = data
    self.positionPriority = positionPriority
  }
  
  init(_ imageData: ImageData, _ positionPriority: Int? = nil) {
    self.id = imageData.id.rawValue
    self.data = imageData.data
    self.positionPriority = positionPriority
  }
//    // UPDATE PROTOCOL
//    func updateFromValueType(_ value: ImageData) {
//        self.data = value.data
//        self.positionPriority = value.positionPriority
//    }
}

// MARK: - ImageData
/// Essentially a `Data` wrapper, that when an instance is successfully created,
/// the **immutable data** stored is **fully image compatible.**
///
/// This type cannot initialize successfully unless the data can be converted into a `UIImage`, which even
/// works when being encoded or decoded (`Codable`)
///
/// `Image` computed property force unwraps based on premise of initialization
///
/// ```
/// let imageD1 = ImageData(data: Data()) // Nope.
/// let imageD2 = ImageData(data: String("foo").data(using: .utf8)!) // Nope.
/// let imageD3 = ImageData(data: (try? Data(contentsOf: URL(fileURLWithPath: "foo.txt")))!) // Nope.
///
/// let imageD4 = ImageData(data: (try? Data(contentsOf: URL(fileURLWithPath: "foo.jpg")))!) // Successful!
/// let imageD5 = ImageData(data: UIImage(systemName: "square")!.pngData()!) // Successful!
/// ```
///
/// **Encoding Invalid Values**
///
/// Encoding a value with an invalid value is literally impossible because you can never initialize an instance
/// if the data does not successfully initialize a UIImage, and even if that somehow magically didn't happen,
/// the decoder conformance initializer performs the exact same check.
///
/// **Init from Decoding Invalid Values**
///
/// Initializing an invalid value from decoding should be literally impossible, because the decoder has the same check
/// as the initializer to check if the data initializes a UIImage.
///
struct ImageData: Equatable, Codable, Identifiable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  let data: Data
  let image: Image
  
  init?(id: ID, data: Data) {
    guard let uiImage = UIImage(data: data) else { return nil }
    self.image = Image(uiImage: uiImage)
    self.data = data
    self.id = id
  }
  
  init?(_ sdData: SDData) {
    self.init(id: .init(sdData.id), data: sdData.data)
  }
  
  enum CodingKeys: CodingKey {
    case id
    case data
  }
  
  enum ParseError: Error { case failure }
  
  init(from decoder: Decoder) throws {
    enum ParseError: Error { case failure }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(ID.self, forKey: .id)
    self.data = try container.decode(Data.self, forKey: .data)
    guard let uiImage = UIImage(data: data) else { throw ParseError.failure  }
    self.image = Image(uiImage: uiImage)
  }
  
  func encode(to encoder: Encoder) throws {
    enum ParseError: Error { case failure }
    guard let _ = UIImage(data: self.data) else { throw ParseError.failure  }
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(data, forKey: .data)
  }
}
