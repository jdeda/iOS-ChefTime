import SwiftUI
import ComposableArchitecture
import Tagged

struct StepsListView: View {
  @State var isExpanded: Bool = true
  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      Text("Hello, World!")
        .accentColor(.accentColor)
    } label: {
      Text("Steps")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.primary)
    }
    .accentColor(.primary)
  }
}

struct StepsListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView {
        StepsListView()
      }
      .padding()
    }
  }
}

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
