import SwiftUI

// MARK: - Possible to make this a unique Reducer?
// TODO: Not really needed here anymore, should be moved into RecipeList
struct IngredientStepper: View {
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
        .font(.title3)
        .fontWeight(.bold)
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
