import SwiftUI
import ComposableArchitecture
import Tagged
import Combine

// TODO: Vertical Text Fields
// TODO: Swipe Gestures
// TODO: Number TextField still has bugs
//        1. fixed size means the row refreshes in a ugly way
//        2. typing invalid text still refreshes in a ugly way
//        3. sometimes editing another textfield moves text that
//           shouldn't move whatsoever

// MARK: - View
struct IngredientView: View {
  let store: StoreOf<IngredientReducer>
  
  var body: some View {
    WithViewStore(store, observe: \.viewState) { viewStore in
      HStack(alignment: .top) {
        
        // Checkbox
        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
          .fontWeight(.medium)
          .onTapGesture {
            viewStore.send(.isCompleteButtonToggled)
          }
          .padding([.top], 2)
        
        // Name
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.name)" },
            send: { .ingredientNameEdited($0) }
          ),
          axis: .vertical
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        // Amount
        TextField(
          "...",
          text: viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { .ingredientAmountEdited($0) }
          )
        )
        .keyboardType(.numberPad)
        .numbersOnly(
          viewStore.binding(
            get: { $0.ingredientAmountString },
            send: { .ingredientAmountEdited($0) }
          ),
          includeDecimal: true
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
        
        // Measurement
        TextField(
          "...",
          text: viewStore.binding(
            get: { "\($0.ingredient.measure)" },
            send: { .ingredientMeasureEdited($0) }
          )
        )
        .fixedSize()
        .autocapitalization(.none)
        .autocorrectionDisabled()
      }
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .accentColor(.accentColor)
      .contextMenu {
        // TODO: This would be nice as a swipe action.
        Button(role: .destructive){
          viewStore.send(.delegate(.swipedToDelete), animation: .default)
        } label: {
          Text("Delete")
        }
      }
    }
  }
}

//// MARK: - View 
//struct IngredientView2: View {
//  let store: StoreOf<IngredientReducer>
//
//  var body: some View {
//    WithViewStore(store, observe: \.viewState) { viewStore in
//      HStack(alignment: .top) {
//        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
//          .fontWeight(.medium)
//          .onTapGesture {
//            viewStore.send(.isCompleteButtonToggled)
//          }
//          .padding([.top], 2)
//        VStack(alignment: .leading) {
//          TextField("Untitled Ingredient", text: viewStore.binding(
//            get: { "\($0.ingredient.name)" },
//            send: { .ingredientNameEdited($0) }
//          ))
//          .autocapitalization(.none)
//          .autocorrectionDisabled()
////          .fontWeight(.medium)
//          HStack(spacing: 5) {
//            TextField("0  ", text: viewStore.binding(
//              get: { $0.ingredientAmountString },
//              send: { .ingredientAmountEdited($0) }
//            ))
//            .keyboardType(.numberPad)
//            .numbersOnly(
//              viewStore.binding(
//                get: { $0.ingredientAmountString },
//                send: { .ingredientAmountEdited($0) }
//              ),
//              includeDecimal: true
//            )
//            .scaledToFit()
//
//            TextField("Untitled Measurement", text: viewStore.binding(
//              get: { "\($0.ingredient.measure)" },
//              send: { .ingredientMeasureEdited($0) }
//            ))
//            .autocapitalization(.none)
//            .autocorrectionDisabled()
//            Spacer()
//          }
//        }
//      }
//      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
//      .accentColor(.accentColor)
//      .swipeActions {
//        Button(role: .destructive) {
//          viewStore.send(.delegate(.swipedToDelete))
//        } label: {
//          Image(systemName: "trash")
//        }
//      }
//    }
//  }
//}

//// MARK: - View
//struct IngredientView: View {
//  let store: StoreOf<IngredientReducer>
//
//  var body: some View {
//    WithViewStore(store, observe: \.viewState) { viewStore in
//      HStack(alignment: .top) {
//        VStack(alignment: .leading) {
//          TextField("Untitled Ingredient", text: viewStore.binding(
//            get: { "\($0.ingredient.name)" },
//            send: { .ingredientNameEdited($0) }
//          ))
//          .autocapitalization(.none)
//          .autocorrectionDisabled()
////          .fontWeight(.medium)
//          HStack(spacing: 5) {
//            TextField("0  ", text: viewStore.binding(
//              get: { $0.ingredientAmountString },
//              send: { .ingredientAmountEdited($0) }
//            ))
//            .keyboardType(.numberPad)
//            .numbersOnly(
//              viewStore.binding(
//                get: { $0.ingredientAmountString },
//                send: { .ingredientAmountEdited($0) }
//              ),
//              includeDecimal: true
//            )
//            .scaledToFit()
//
//            TextField("Untitled Measurement", text: viewStore.binding(
//              get: { "\($0.ingredient.measure)" },
//              send: { .ingredientMeasureEdited($0) }
//            ))
//            .autocapitalization(.none)
//            .autocorrectionDisabled()
//            Spacer()
//          }
//        }
//
//        Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
//          .fontWeight(.medium)
//          .onTapGesture {
//            viewStore.send(.isCompleteButtonToggled)
//          }
//          .padding([.top], 2)
//        Spacer()
//      }
//      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
//      .accentColor(.accentColor)
//      .swipeActions {
//        Button(role: .destructive) {
//          viewStore.send(.delegate(.swipedToDelete))
//        } label: {
//          Image(systemName: "trash")
//        }
//      }
//    }
//  }
//}

// MARK: - Reducer
struct IngredientReducer: ReducerProtocol {
  struct State: Equatable, Identifiable {
    typealias ID = Tagged<Self, UUID>
    
    let id: ID
    var viewState: ViewState
  }
  
  enum Action: Equatable {
    case ingredientNameEdited(String)
    case ingredientAmountEdited(String)
    case ingredientMeasureEdited(String)
    case isCompleteButtonToggled
    case delegate(DelegateAction)
  }
  
  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .ingredientNameEdited(newName):
        state.viewState.ingredient.name = newName
        return .none
        
      case let .ingredientAmountEdited(newAmountString):
        // TODO: Fix...
        state.viewState.ingredientAmountString = newAmountString
        state.viewState.ingredient.amount = Double(newAmountString) ?? 0
        //        let newAmount = Double(newAmountString) ?? -1
        //        let newAmountString = String(newAmount)
        //        state.viewState.ingredientAmountString = newAmountString
        //        state.viewState.ingredient.amount = newAmount
        //        if newAmount == -1 { fatalError() }
        return .none
        
      case let .ingredientMeasureEdited(newMeasure):
        state.viewState.ingredient.measure = newMeasure
        return .none
        
      case .isCompleteButtonToggled:
        state.viewState.isComplete.toggle()
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}
extension IngredientReducer {
  struct ViewState: Equatable {
    var ingredient: Recipe.Ingredients.Ingredient
    var ingredientAmountString: String
    var isComplete: Bool = false
    
    init(ingredient: Recipe.Ingredients.Ingredient) {
      self.ingredient = ingredient
      self.ingredientAmountString = String(ingredient.amount)
    }
  }
}

extension IngredientReducer {
  enum DelegateAction: Equatable {
    case swipedToDelete
  }
}

// MARK: - Previews
struct IngredientView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ScrollView
      {
        IngredientView(store: .init(
          initialState: .init(
            id: .init(),
            viewState: .init(
              ingredient: Recipe.mock.ingredients.first!.ingredients.first!
            )
          ),
          reducer: IngredientReducer.init,
          withDependencies: { _ in
            // TODO:
          }
        ))
      }
      .listStyle(.plain)
      .padding()
    }
    //    NavigationStack {
    //      ScrollView
    //      {
    //        IngredientView2(store: .init(
    //          initialState: .init(
    //            id: .init(),
    //            viewState: .init(
    //              ingredient: Recipe.mock.ingredients.first!.ingredients.first!
    //            )
    //          ),
    //          reducer: IngredientReducer.init,
    //          withDependencies: { _ in
    //            // TODO:
    //          }
    //        ))
    //      }
    //      .listStyle(.plain)
    //      .padding()
    //    }
  }
}

// MARK: - NumbersOnlyViewModifier (Private)
private struct NumbersOnlyViewModifier: ViewModifier {
  @Binding var text: String
  var includeDecimal: Bool
  
  func body(content: Content) -> some View {
    content
      .keyboardType(includeDecimal ? .decimalPad : .numberPad)
      .onReceive(Just(text)) { newValue in
        var numbers = "0123456789"
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        if includeDecimal {
          numbers += decimalSeparator
        }
        if newValue.components(separatedBy: decimalSeparator).count-1 > 1 {
          let filtered = newValue
          self.text = String(filtered.dropLast())
        }
        else {
          let filtered = newValue.filter { numbers.contains($0) }
          if filtered != newValue {
            self.text = filtered
          }
        }
      }
  }
}

private extension View {
  func numbersOnly(_ text: Binding<String>, includeDecimal: Bool = false) -> some View {
    self.modifier(NumbersOnlyViewModifier(text: text, includeDecimal: includeDecimal))
  }
}

//struct IngredientViewX: View {
//  var body: some View {
//      HStack(alignment: .top) {
//
//        // Checkbox
//        Image(systemName: "square")
//          .fontWeight(.medium)
//          .padding([.top], 2)
//
//        // Name
//        TextField("...", text: .constant(""))
//        .autocapitalization(.none)
//        .autocorrectionDisabled()
//
//        // Amount
//        TextField("...", text: .constant(""))
//        .fixedSize()
//
//        // Measurement
//        TextField("...", text: .constant(""))
//        .fixedSize()
//      }
//      .foregroundColor(.secondary)
//      .accentColor(.accentColor)
//  }
//}

struct IngredientViewX: View {
  var body: some View {
    HStack(alignment: .top) {
      
      // Checkbox
      Image(systemName: "square")
        .fontWeight(.medium)
        .padding([.top], 2)
      
      // Name
      TextField("...", text: .constant(""))
        .disabled(true)
      
      // Amount
      TextField("...", text: .constant(""))
        .disabled(true)
        .fixedSize()
      
      // Measurement
      TextField("...", text: .constant(""))
        .disabled(true)
        .fixedSize()
      
      Image(systemName: "plus")
        .fontWeight(.medium)
        .padding([.top], 2)
    }
    .foregroundColor(.secondary)
    .accentColor(.accentColor)
  }
}
