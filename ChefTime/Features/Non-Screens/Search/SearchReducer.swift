import Foundation
import ComposableArchitecture

// MARK: - Reducer
struct SearchReducer: Reducer {
  struct State: Equatable {
    var query: String
    var length: Int
    var results: IdentifiedArrayOf<SearchResult>
    var loadStatus: LoadStatus
    
    // TODO: Make sure this string always gets recieved to be lowercased.
    init(query: String) {
      self.query = query.lowercased()
      self.length = 25 // TODO: Magic number
      self.results = []
      self.loadStatus = .didNotLoad
    }
  }
  
  enum Action: Equatable {
    case task
    case fetchRecipes
    case fetchRecipesSuccess([Recipe])
    case delegate(DelegateAction)
    
    enum DelegateAction: Equatable {
      case searchResultTapped(Recipe.ID)
    }
  }
  
  @Dependency(\.database) var database
  @Dependency(\.continuousClock) var clock
  
  enum FetchRecipesID: Hashable { case debounce }
  
  var body: some Reducer<SearchReducer.State, SearchReducer.Action> {
    Reduce<SearchReducer.State, SearchReducer.Action> { state, action in
      switch action {
      case .task:
        return .send(.fetchRecipes)
        
      case .fetchRecipes:
        guard state.results.isEmpty else { return .none }
        state.results = []
        state.loadStatus = .isLoading
        return .run { [query = state.query] send in
          try await self.clock.sleep(for: .seconds(1))
          guard !Task.isCancelled else { return }
          let recipes = await database.searchRecipes(query)
          await send(.fetchRecipesSuccess(recipes), animation: .default)
        }
        .cancellable(id: FetchRecipesID.debounce, cancelInFlight: true)
        
      case let .fetchRecipesSuccess(recipes):
        let sorted = recipes.sorted { r1, r2 in
          guard let l1 = stringSearchResultRangeCount(source: recipeDescription(r1), query: state.query, length: state.length) 
          else { return true }
          guard let l2 = stringSearchResultRangeCount(source: recipeDescription(r2), query: state.query, length: state.length) 
          else { return false }
          return l1 > l2
        }
        let newResults: [SearchResult] = sorted.map({
          .init(
            id: $0.id,
            title: $0.name,
            formattedDateString: $0.lastEditDate.formattedDate,
            queryRegexDescriptionString: queryRegexDescriptionString(
              recipe: $0,
              query: state.query,
              length: state.length
            )
          )
        })
        state.results = .init(uniqueElements: newResults)
        state.loadStatus = .didLoad
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
  
}

// TODO: Could be extended into having more information, such as folder name, etc
struct SearchResult: Identifiable, Equatable {
  let id: Recipe.ID
  let title: String
  let formattedDateString: String
  let queryRegexDescriptionString: String
}

// MARK: - Search Result Functionality√
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
private func recipeDescription(_ recipe: Recipe) -> String {
  let s1 = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
  
  let s2 = recipe.aboutSections.reduce(into: "", {
    $0 += $1.description + " " + $1.name + " "
  })
    .trimmingCharacters(in: .whitespacesAndNewlines)
  
  let s3 = recipe.ingredientSections.reduce(into: "", {
    let s = $1.ingredients.reduce(into: "", { $0 += $1.name + " " })
    $0 += $1.name + " " + s
  })
    .trimmingCharacters(in: .whitespacesAndNewlines)
  
  let s4 = recipe.stepSections.reduce(into: "", {
    let s = $1.steps.reduce(into: "", { $0 += $1.description + " "})
    $0 += $1.name + " " + s
  }).trimmingCharacters(in: .whitespacesAndNewlines)
  
  return s1 + " " + s2 + " " + s3 + " " + s4
}

private func queryRegexDescriptionString(recipe: Recipe, query: String, length: Int) -> String {
  let recipeDescription = recipeDescription(recipe)
  guard let result = stringSearchResult(source: recipeDescription, query: query, length: length),
        !result.isEmpty
  else {
    return recipeDescription.split(separator: " ").reduce("", { partial, next in
      let new = partial + " " + next
      return new.count > 20 ? partial : new
    })
  }
  
  return result
}
