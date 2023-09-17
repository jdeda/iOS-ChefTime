import SwiftUI
import ComposableArchitecture
import Tagged

// MARK: - View
struct SearchView: View {
  let store: StoreOf<SearchReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        LazyVStack {
          HStack {
            Text("Top Results")
              .textTitleStyle()
            Spacer()
            Text("\(viewStore.results.prefix(3).count) Found")
              .font(.body)
              .foregroundColor(.secondary)
              .textCase(nil)
            }
          .padding(.bottom, 5)
          
          ForEach(viewStore.results.prefix(3)) { result in
            HStack {
              VStack(alignment: .leading) {
                HighlightedText(result.recipe.name, matching: viewStore.query, caseInsensitive: true)
                  .lineLimit(1)
                  .fontWeight(.medium)
                HStack(spacing: 4) {
                  Text(Date().formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                  HighlightedText(result.description, matching: viewStore.query, caseInsensitive: true)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                HStack(spacing: 4)  {
                  Image(systemName: "folder")
                  Text("Standard")
                }
                .font(.caption)
                .foregroundColor(.secondary)
              }
              Spacer()
            }
            Divider()
          }
        }
        .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
        .accentColor(.yellow)
        
        LazyVStack {
          HStack {
            Text("All Results")
              .textTitleStyle()
            Spacer()
            Text("\(viewStore.results.count) Found")
              .font(.body)
              .foregroundColor(.secondary)
              .textCase(nil)
          }
          .padding(.bottom, 5)
          
          ForEach(viewStore.results) { result in
            HStack {
              VStack(alignment: .leading) {
                HighlightedText(result.recipe.name, matching: viewStore.query, caseInsensitive: true)
                  .lineLimit(1)
                  .fontWeight(.medium)
                HStack(spacing: 4) {
                  Text(Date().formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                  HighlightedText(result.description, matching: viewStore.query, caseInsensitive: true)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                HStack(spacing: 4)  {
                  Image(systemName: "folder")
                  Text("Standard")
                }
                .font(.caption)
                .foregroundColor(.secondary)
              }
              Spacer()
            }
            Divider()
          }
        }
        .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
        .accentColor(.yellow)
      }
      .task {
        await viewStore.send(.task, animation: .default).finish()
      }
    }
  }
}

// MARK: - HighlightedText View
struct HighlightedText: View {
  let text: String
  let matching: String
  let caseInsensitive: Bool
  
  init(_ text: String, matching: String, caseInsensitive: Bool = false) {
    self.text = text
    self.matching = matching
    self.caseInsensitive = caseInsensitive
  }
  
  var body: some View {
    guard let regex = nsRegex(query: matching, caseInsensitive: caseInsensitive)
    else { return Text(text) }
    let range = NSRange(location: 0, length: text.count)
    let matches = regex.matches(in: text, options: .withTransparentBounds, range: range)
    
    return text.enumerated()
      .map { (char) -> Text in
        guard matches.filter({$0.range.contains(char.offset)}).count == 0
        else { return Text(String(char.element)).foregroundColor(.accentColor) }
        return Text(String(char.element))
      }
      .reduce(Text("")) { (a, b) -> Text in
        return a + b
      }
  }
}

// MARK: - Reducer
struct SearchReducer: Reducer {
  struct State: Equatable {
    var recipes: IdentifiedArrayOf<Recipe>
    var results: IdentifiedArrayOf<SearchResult> = []
    var query: String
    var length: Int
  }
  
  enum Action: Equatable {
    case task
    case resultSuccess(SearchResult)
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard state.results.isEmpty else { return .none }
        return .run { [recipes = state.recipes] send in
          await withTaskGroup(of: Void.self) { taskGroup in
            for recipe in recipes {
              taskGroup.addTask {
                let r = SearchResult(id: .init(rawValue: uuid()), recipe: recipe)
                await send(.resultSuccess(r), animation: .default)
              }
            }
          }
        }
        
      case let .resultSuccess(searchResult):
        state.results.append(searchResult)
        return .none
      }
    }
  }
}

struct SearchResult: Identifiable, Equatable {
  typealias ID = Tagged<Self, UUID>
  
  let id: ID
  let recipe: Recipe
  var description: String = ""
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

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
  static var previews: some View {
    SearchView(store: .init(
      initialState: .init(recipes: Folder.longMock.recipes, query: "burger", length: 25),
      reducer: SearchReducer.init
    ))
  }
}

