import SwiftUI

struct IngredientsView: View {
  let ingredients: RecipeZ.Ingredients
  
  init(ingredients: RecipeZ.Ingredients = RecipeZ.mock.ingredients.first!) {
    self.ingredients = ingredients
  }
  
  var body: some View {
    ForEach(ingredients.ingredients, id: \.name) { ingredient in
      HStack {
        HStack(alignment: .top) {
          Image(systemName: ingredient.amount == 2 ? "checkmark.square" : "square")
            .resizable()
            .frame(width: 15, height: 15)
            .padding([.top], 4)
          
          Text("\(Int(ingredient.amount)) \(ingredient.measure) \(ingredient.name)")
            .fontWeight(.medium)
        }
        .foregroundColor(ingredient.amount == 2 ? .secondary : .primary)
        Spacer()
      }
    }
  }
}

struct IngredientsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        IngredientsView()
      }
      .padding()
    }
  }
}
