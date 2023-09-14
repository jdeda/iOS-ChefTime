import SwiftUI
import ComposableArchitecture

// MARK: - View
struct SearchView: View {
  let store: StoreOf<SearchReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Section {
        ForEach(viewStore.topHits) { recipe in
          Row(recipe: recipe, query: viewStore.query)
            .onTapGesture {
              viewStore.send(.recipeTapped(recipe.id))
            }
        }
      } header: {
        HStack {
          Text("Top Results")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            . textCase(nil)
          
          Spacer()
          Text("\(viewStore.topHits.count) Found")
            .font(.body)
            .foregroundColor(.secondary)
            .textCase(nil)
        }
      }
      Section {
        ForEach(viewStore.recipes) { recipe in
          Row(recipe: recipe, query: viewStore.query)
            .onTapGesture {
              viewStore.send(.recipeTapped(recipe.id))
            }
        }
      } header: {
        HStack {
          Text("All Results")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .textCase(nil)
          Spacer()
          Text("\(viewStore.recipes.count) Found")
            .font(.body)
            .foregroundColor(.secondary)
            .textCase(nil)
        }
      }
    }
  }
}

// MARK: - Helper Views
extension SearchView {
  struct Row: View {
    let recipe: Recipe
    let query: String
    let length = 25
    
    var recipeBodyQueryDescription: String {
      guard let result = stringSearchResult(source: recipe.description, query: query, length: length)
      else { return recipe.name }
      if result.isEmpty { return recipe.name}
      return result
    }
    
    var body: some View {
      VStack(alignment: .leading) {
        HighlightedText(recipe.name, matching: query, caseInsensitive: true)
          .lineLimit(1)
          .fontWeight(.medium)
        HStack(spacing: 4) {
          Text(Date().formattedDate)
            .font(.caption)
            .foregroundColor(.secondary)
          HighlightedText(recipeBodyQueryDescription, matching: query, caseInsensitive: true)
            .lineLimit(1)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        HStack(spacing: 4)  {
          Image(systemName: "folder")
          Text(recipe.name)
        }
        .font(.caption)
        .foregroundColor(.secondary)
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

// MARK: - Recipe description helper
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
struct SearchView_Previews: PreviewProvider {
  static var previews: some View {
    SearchView(store: .init(
      initialState: .init(query: "", recipes: Folder.longMock.recipes),
      reducer: SearchReducer.init
    ))
  }
}
