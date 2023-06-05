//import SwiftUI
//import Tagged
//
//struct RecipeView: View {
//  let maxW = UIScreen.main.bounds.width * 0.85
//  let recipe: Recipe = .mock
//  
//  var body: some View {
//    ScrollView {
//      Group {
//        Image("recipe_09")
//          .resizable()
//          .scaledToFill()
//          .frame(width: maxW, height: maxW)
//          .clipShape(RoundedRectangle(cornerRadius: 15))
//          .padding([.bottom])
//      }
//      
//      // About.
//      Collapsible(collapsed: false) {
//        Text("About")
//          .font(.title)
//          .fontWeight(.bold)
//      } content: {
//        Text(recipe.notes)
//      }
//      
//      Divider()
//      
//      // Ingredients.
//      Collapsible(collapsed: false) {
//        Text("Ingredients")
//          .font(.title)
//          .fontWeight(.bold)
//      } content: {
//        ForEach(recipe.ingredients, id: \.name) { ingredients in
//          Collapsible(collapsed: true) {
//            Text(ingredients.name)
//              .font(.title3)
//              .fontWeight(.bold)
//          } content: {
//            IngredientsView(ingredients: ingredients)
//          }
//          Divider()
//        }
//      }
//      
//      Divider()
//      
//      // Steps.
//      Collapsible(collapsed: false) {
//        Text("Steps")
//          .font(.title)
//          .fontWeight(.bold)
//      } content: {
//        ForEach(mockSteps, id: \.name) { stepsL in
//          Collapsible(collapsed: false) {
//            Text(stepsL.name)
//              .font(.title3)
//              .fontWeight(.bold)
//          } content: {
//            LazyVStack(alignment: .leading) {
//              Rectangle()
//                .fill(.clear)
//              ForEach(Array(stepsL.steps.enumerated()), id: \.offset) { pair in
//                VStack(alignment: .leading) {
//                  Text("Step \(pair.offset + 1)")
//                    .fontWeight(.bold)
//                  Text("\(pair.element.1)")
//                  Image(pair.element.0)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: maxW, height: 200)
//                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                  Spacer()
//                }
//                Rectangle()
//                  .fill(.clear)
//              }
//            }
//            //            .frame(width: .infinity)
//          }
//          Divider()
//        }
//      }
//    }
//    //    .frame(width: .infinity)
//    .padding()
//    .navigationTitle(recipe.name)
//  }
//}
//
//
//
//struct RecipeView_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationStack {
//      RecipeView()
//        .scrollContentBackground(.hidden)
//        .background {
//          Image(systemName: "recipe_05")
//            .resizable()
//            .scaledToFill()
//            .blur(radius: 10)
//            .ignoresSafeArea()
//        }
//    }
//  }
//}
