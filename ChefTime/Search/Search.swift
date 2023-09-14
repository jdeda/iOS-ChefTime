import SwiftUI
import ComposableArchitecture

// MARK: - Reducer
struct SearchReducer: Reducer {
  struct State: Equatable {
    let query: String
    var recipes: IdentifiedArrayOf<Recipe>
    var resultLength: Int = 25
    
    var topHits: IdentifiedArrayOf<Recipe> {
      .init(recipes.prefix(3))
    }
  }
  
  enum Action: Equatable {
    case recipeTapped(Recipe.ID)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .recipeTapped:
        return .none
      }
    }
  }
  
//  func sortRecipes() {
//    self.recipes = .init(uniqueElements: recipes.sorted { r1, r2 in
//      guard let l1 = stringSearchResultRangeCount(source: r1.description, query: query, length: resultLength) else { return true }
//      guard let l2 = stringSearchResultRangeCount(source: r2.description, query: query, length: resultLength) else { return false }
//      return l1 > l2
//    })
//  }
}

// MARK: - Search Result Functionality

/// Returns a string containing as many words containing the query in the source, up to a given length,
/// case insensitively or not.
///
/// Words are represented as a sequence of characters, separated by any whitespace.
/// Resulting string does not have partial words, so entire words will be cut off.
///
/// i.e.
///
///  let result = stringSearchResult(
///   source: "molly sold seashells at the seashore",
///   query: "sea",
///   length: "50"
///   caseInsensitive: true
///  )
///
///  print(result) <-- "sold seashells seashore"
///
///  let result = stringSearchResult(
///   source: "molly sold seashells at the seashore",
///   query: "sea",
///   length: "20"
///   caseInsensitive: true
///  )
///
///  print(result) <-- "sold seashells"
///
///
/// - Parameters:
///   - source: The string to check
///   - query: The string representing what the source should contain
///   - length: The maximum length of the resuult
///   - caseInsensitive: boolean representing if search should be case insensitive
///
func stringSearchResult(
  source sourceRaw: String,
  query queryRaw: String,
  length: Int,
  caseInsensitive: Bool = true
) -> String? {
  
  let source: String = { caseInsensitive ? sourceRaw.lowercased() : sourceRaw }()
  let query: String = { caseInsensitive ? queryRaw.lowercased() : queryRaw }()
  
  guard let regex: Regex<AnyRegexOutput> = {
    guard let reg = nsRegex(query: query, caseInsensitive: caseInsensitive)
    else { return nil }
    return try? Regex(reg.pattern)
  }()
  else { return nil }
  
  let ranges = source.ranges(of: regex)
  let foundWords: [String] = ranges.compactMap { range -> String? in
    
    // Go back till you find a space, this will be the new range start index
    guard let newStartIdx: Int = {
      let leftSide = source[source.startIndex...range.lowerBound]
      var x = -1
      for (idx, char) in leftSide.reversed().enumerated() {
        if char == " " {
          x = idx
          break
        }
      }
      let leftOffset = source.distance(from: source.startIndex, to: range.lowerBound)
      let i = x == -1 ? nil : leftOffset - x
      return i
    }()
    else { return nil }
    
    // Go back forward till you find a space, this will be the new range end index
    guard let newEndIdx: Int = {
      let rightSide = source[range.upperBound..<source.endIndex]
      var x = -1
      for (idx, char) in rightSide.enumerated() {
        if char == " " {
          x = idx
          break
        }
      }
      let rightOffset = source.distance(from: source.startIndex, to: range.upperBound)
      let i = x == -1 ? nil : rightOffset + x
      return i
    }()
    else { return nil }
    
    // Return the extracted string.
    let x = source.index(source.startIndex, offsetBy: newStartIdx)
    let y = source.index(source.startIndex, offsetBy: newEndIdx)
    let finalStr = String(source[x...y])
    return String(finalStr)
  }
  .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)}
  
  var finalResult = ""
  for word in foundWords {
    let new = finalResult + " " + word + " "
    if new.count < length {
      finalResult = new
    }
  }
  finalResult = String(finalResult[finalResult.startIndex..<finalResult.endIndex])
  return finalResult
}


// MARK: - Regex range helper calculates maximum distance from 0, the range of the source string against the regex result
func stringSearchResultRangeCount(
  source sourceRaw: String,
  query queryRaw: String,
  length: Int,
  caseInsensitive: Bool = true
) -> Int? {
  
  let source: String = { caseInsensitive ? sourceRaw.lowercased() : sourceRaw }()
  let query: String = { caseInsensitive ? queryRaw.lowercased() : queryRaw }()
  
  guard let regex: Regex<AnyRegexOutput> = {
    guard let reg = nsRegex(query: query, caseInsensitive: caseInsensitive)
    else { return nil }
    return try? Regex(reg.pattern)
  }()
  else { return nil }
  
  return source.ranges(of: regex).reduce(0, { $0 + source.distance(from: $1.lowerBound, to: $1.upperBound) })
}

// MARK: - Regex helper make a regex via a query string and case sensitivity
func nsRegex(query: String, caseInsensitive: Bool = true) -> NSRegularExpression? {
  try? NSRegularExpression(
    pattern: NSRegularExpression.escapedPattern(for: query)
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(
        options: .regularExpression,
        locale: .current
      )
    ,
    options: caseInsensitive ? .caseInsensitive : .init()
  )
}

// MARK: - Date format helper
extension Date {
  // String representation of a date in "MM/dd/YY" format
  var formattedDate: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/YY"
    return dateFormatter.string(from: self)
  }
  
  // String representation of a date in "EEEE MMM d, yyyy, h:mm a" format
  var formattedDateVerbose: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE MMM d, yyyy, h:mm a"
    return "Created \(dateFormatter.string(from: self))"
  }
}

// MARK: - Reciper description helper
private extension Recipe {
  var description: String {
    let s1 = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let s2 = self.aboutSections.reduce(into: "", {
      $0 += ($1.description + " " + $1.name) + " "
    }).trimmingCharacters(in: .whitespacesAndNewlines)
    
    let s3 = self.ingredientSections.reduce(into: "", {
      $0 += ($1.name + " " + $1.ingredients.reduce(into: "", { $0 += $1.name + " " }) + " ")
    }).trimmingCharacters(in: .whitespacesAndNewlines)
    
    let s4 = self.stepSections.reduce(into: "", {
      $0 += $1.name + " " + $1.steps.reduce(into: "", { $0 += $1.description + " "})
    }).trimmingCharacters(in: .whitespacesAndNewlines)
    
    return s1 + " " + s2 + " " + s3 + " " + s4
  }
}

// MARK: - Preview
struct _SearchView_Previews: PreviewProvider {
  static var previews: some View {
    SearchView(store: .init(
      initialState: .init(query: "", recipes: Folder.longMock.recipes),
      reducer: SearchReducer.init
    ))
  }
}
