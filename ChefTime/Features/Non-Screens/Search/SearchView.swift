import SwiftUI
import ComposableArchitecture
import Tagged

/// Search Feature
/// 1. Whenever a user types, he is writing to a Binding<String> which the reducer recieves and
/// immediately begins a stream of any recipes that "contain" this string. Whenever a new string is recieved
/// that is different (perhaps excluding trailing or leading whitespace and newlines) it clears all its results
/// and tears down the current stream replacing it with a new one with the new query.
///

struct SearchView: View {
  let store: StoreOf<SearchReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        switch viewStore.loadStatus {
        case .didLoad:
          if viewStore.results.isEmpty {
            Text("Top Results")
              .textTitleStyle()
          }
          else {
            CoreSearchView(store: store)
          }
        case .didNotLoad:
          Text("Nothing Found.")
            .textTitleStyle()
        case .isLoading:
          ProgressView()
        }
      }
      .task {
        await viewStore.send(.task, animation: .default).finish()
      }
    }
  }
}

private struct CoreSearchView: View {
  let store: StoreOf<SearchReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        LazyVStack {
          HStack {
            Text("Results")
              .textTitleStyle()
            Spacer()
            Text("\(viewStore.results.count) Found")
              .font(.body)
              .foregroundColor(.secondary)
              .textCase(nil)
          }
          .padding(.bottom, 5)
          
          ForEach(viewStore.results) { result in
//            HStack {
//              VStack(alignment: .leading) {
//                HighlightedText(result.title, matching: viewStore.query, caseInsensitive: true)
//                  .lineLimit(1)
//                  .fontWeight(.medium)
//                HStack(spacing: 4) {
//                  Text(result.description)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                  HighlightedText(result.description, matching: viewStore.query, caseInsensitive: true)
//                    .lineLimit(1)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                }
//                .font(.caption)
//                .foregroundColor(.secondary)
//              }
//              Spacer()
//            }
            VStack(alignment: .leading) {
              HighlightedText(result.title, matching: viewStore.query, caseInsensitive: true)
                .lineLimit(1)
                .fontWeight(.medium)
              HStack(spacing: 4) {
                Text(result.formattedDateString)
                  .font(.caption)
                  .foregroundColor(.secondary)
                HighlightedText(result.queryRegexDescriptionString, matching: viewStore.query, caseInsensitive: true)
                  .lineLimit(1)
                  .font(.caption)
                  .foregroundColor(.secondary)
                Spacer()
              }
              .font(.caption)
              .foregroundColor(.secondary)
            }
            .onTapGesture {
              viewStore.send(.delegate(.searchResultTapped(result.id)))
            }
            Divider()
          }
        }
        .padding(.horizontal, maxScreenWidth.maxWidthHorizontalOffset * 0.5)
        .accentColor(.yellow)
      }
    }
  }
}

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

#Preview {
  SearchView(store: .init(
    initialState: .init(query: "onion"),
    reducer: SearchReducer.init
  ))
}
