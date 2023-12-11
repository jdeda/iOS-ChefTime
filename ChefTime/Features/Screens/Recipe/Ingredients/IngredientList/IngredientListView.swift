import SwiftUI
import ComposableArchitecture

// TODO: Why is there a focus state
struct IngredientListView: View {
  let store: StoreOf<IngredientsListReducer>
  @FocusState private var focusedField: IngredientsListReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      DisclosureGroup(isExpanded: viewStore.$isExpanded) {
        LazyVStack {
          ForEachStore(store.scope(state: \.ingredientSections, action: IngredientsListReducer.Action.ingredientSections)) { childStore in
            if viewStore.ingredientSections.count == 1 {
              IngredientSectionNonGrouped(store: childStore)
                .contentShape(Rectangle())
                .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
            }
            else {
              IngredientSection(store: childStore)
                .contentShape(Rectangle())
                .focused($focusedField, equals: .row(ViewStore(childStore, observe: \.id).state))
            }
            Divider()
              .padding(.bottom, 5)
          }
        }
      }
      label : {
        Text("Ingredients")
          .textTitleStyle()
        Spacer()
      }
      .accentColor(.primary)
      .synchronize(viewStore.$focusedField, $focusedField)
      .disclosureGroupStyle(CustomDisclosureGroupStyle())
    }
  }
}

private struct IngredientStepper: View {
  @Binding var scale: Double
  
  var scaleString: String {
    switch scale {
    case 0.25: return "1/4"
    case 0.50: return "1/2"
    default:   return String(Int(scale))
    }
  }
  
  var body: some View {
    Stepper(
      value: .init(
        get: { scale },
        set: { scaleStepperButtonTapped($0) }
      ),
      in: 0.25...10.0,
      step: 1.0
    ) {
      Text("Servings \(scaleString)")
        .textSubtitleStyle()
    }
  }
  
  func scaleStepperButtonTapped(_ newScale: Double) {
    let incremented = newScale > scale
    let oldScale = scale
    let newScale: Double = {
      if incremented {
        switch oldScale {
        case 0.25: return 0.5
        case 0.5: return 1.0
        case 1.0..<10.0: return oldScale + 1
        default: return oldScale
        }
      }
      else {
        switch oldScale {
        case 0.25: return 0.25
        case 0.5: return 0.25
        case 1.0: return 0.5
        default: return oldScale - 1
        }
      }
    }()
    scale = newScale
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      IngredientListView(store: .init(
        initialState: .init(recipeSections: Recipe.longMock.ingredientSections),
        reducer: IngredientsListReducer.init
      ))
      .padding()
    }
  }
}
