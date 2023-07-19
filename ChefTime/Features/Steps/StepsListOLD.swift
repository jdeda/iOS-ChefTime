//import SwiftUI
//import ComposableArchitecture
//
//// MARK: - View
//struct StepsListView: View {
//  let store: StoreOf<StepsListReducer>
//  let maxW = UIScreen.main.bounds.width * 0.95
//
//  var body: some View {
//    WithViewStore(store) { viewStore in
//      if viewStore.stepSections.isEmpty {
//        VStack {
//          HStack {
//            Text("Steps")
//              .font(.title)
//              .fontWeight(.bold)
//              .foregroundColor(.primary)
//            Spacer()
//          }
//          HStack {
//            TextField(
//              "Untitled Step Section",
//              text: .constant(""),
//              axis: .vertical
//            )
//            .font(.title3)
//            .fontWeight(.bold)
//            .foregroundColor(.primary)
//            .accentColor(.accentColor)
//            .frame(alignment: .leading)
//            .multilineTextAlignment(.leading)
//            .lineLimit(.max)
//            .autocapitalization(.none)
//            .autocorrectionDisabled()
//            .disabled(true)
//
//            Spacer()
//            Image(systemName: "plus")
//          }
//          .foregroundColor(.secondary)
//        }
//        .onTapGesture {
//          viewStore.send(.addSectionButtonTapped, animation: .default)
//        }
//      }
//      else {
//        DisclosureGroup(isExpanded: .constant(true)) {
//          ForEach(viewStore.stepSections) { section in
//            DisclosureGroup(isExpanded: .constant(true)) {
//              ForEach(Array(zip(section.steps.indices, section.steps)), id: \.0) { index, step in
//                VStack(alignment: .leading) {
//                  Text("Step \(index + 1)")
//                    .font(.caption)
//                    .fontWeight(.medium)
//                    .padding(.bottom, 1)
//                  Text(step.description)
//                  if let data = step.imageData {
//                    dataToImage(data)!
//                      .resizable()
//                      .scaledToFill()
//                      .frame(width: maxW, height: maxW)
//                      .clipShape(RoundedRectangle(cornerRadius: 15))
//                  }
//
//                  Divider()
//                }
//              }
//            } label: {
//              TextField(
//                "Untitled Step Section",
//                text: .constant(section.name),
//                axis: .vertical
//              )
//              .font(.title3)
//              .fontWeight(.bold)
//              .foregroundColor(.primary)
//              .accentColor(.accentColor)
//              .frame(alignment: .leading)
//              .multilineTextAlignment(.leading)
//              .lineLimit(.max)
//              .autocapitalization(.none)
//              .autocorrectionDisabled()
//            }
//
//          }
//        } label : {
//          Text("Steps")
//            .font(.title)
//            .fontWeight(.bold)
//            .foregroundColor(.primary)
//          Spacer()
//        }
//        .accentColor(.primary)
//        .disclosureGroupStyle(CustomDisclosureGroupStyle())
//      }
//    }
//  }
//}
//
//// MARK: - Reducer
//struct StepsListReducer: ReducerProtocol {
//  struct State: Equatable {
//    var stepSections: IdentifiedArrayOf<Recipe.StepSection>
//  }
//
//  enum Action: Equatable {
//    case addSectionButtonTapped
//  }
//
//  @Dependency(\.uuid) var uuid
//
//  var body: some ReducerProtocolOf<Self> {
//    Reduce { state, action in
//      switch action {
//      case .addSectionButtonTapped:
//        state.stepSections.append(.init(
//          id: .init(rawValue: uuid()),
//          name: "",
//          steps: [])
//        )
//        return .none
//      }
//    }
//  }
//}
//
//// MARK: - Preview
//struct StepsListView_Previews: PreviewProvider {
//  static var previews: some View {
//    NavigationStack {
//      ScrollView {
//        StepsListView(store: .init(
//          initialState: .init(
//            //            stepSections: .init(uniqueElements: Recipe.longMock.steps)
//            stepSections: []
//          ),
//          reducer: StepsListReducer.init
//        ))
//        .padding([.horizontal])
//      }
//    }
//  }
//}
//
