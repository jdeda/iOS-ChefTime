import SwiftUI
import ComposableArchitecture
import Combine

struct IngredientView: View {
  let store: StoreOf<IngredientReducer>
  @FocusState private var focusedField: IngredientReducer.FocusField?
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
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
            get: \.ingredient.name,
            send: { .ingredientNameEdited($0) }
          ),
          axis: .vertical
        )
        .submitLabel(.next)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .name)
        .onTapGesture { viewStore.send(.binding(.set(\.$focusedField, .name))) }
        
//        Rectangle()
//          .fill(.clear)
//          .frame(width: 50)
//        
//        // Amount
//        TextField("...", text: viewStore.$ingredientAmountString)
//          .keyboardType(.decimalPad)
//          .numbersOnly(viewStore.$ingredientAmountString, includeDecimal: true)
//          .submitLabel(.next)
//          .fixedSize()
//          .autocapitalization(.none)
//          .autocorrectionDisabled()
//          .focused($focusedField, equals: .amount)
//          .onTapGesture { viewStore.send(.binding(.set(\.$focusedField, .amount))) }
//        
//        // Measurement
//        TextField("...", text: viewStore.binding(
//          get: { $0.ingredient.measure },
//          send: { .ingredientMeasureEdited($0) }
//        ))
//        .fixedSize()
//        .submitLabel(.next)
//        .autocapitalization(.none)
//        .autocorrectionDisabled()
//        .focused($focusedField, equals: .measure)
//        .onSubmit {
//          viewStore.send(.delegate(.insertIngredient(.below)), animation: .default)
//        }
//        .onTapGesture { viewStore.send(.binding(.set(\.$focusedField, .measure))) }
        
      }
      .synchronize(viewStore.$focusedField, $focusedField)
      .foregroundColor(viewStore.isComplete ? .secondary : .primary)
      .toolbar {
        if viewStore.focusedField != nil {
          ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("next") {
              viewStore.send(.keyboardNextButtonTapped, animation: .default)
            }
            .foregroundColor(.primary)
            Button("done") {
              viewStore.send(.keyboardDoneButtonTapped, animation: .default)
            }
            .foregroundColor(.primary)
          }
        }
      }
      .accentColor(.accentColor)
      .contextMenu(menuItems: {
        Button(role: .destructive) {
          viewStore.send(.delegate(.tappedToDelete), animation: .default)
        } label: {
          Text("Delete")
        }
      }, preview: {
        IngredientContextMenuPreview(state: viewStore.state)
          .padding()
      })
    }
  }
}

private struct NumbersOnlyViewModifier: ViewModifier {
  @Binding var text: String
  var includeDecimal: Bool
  
  func body(content: Content) -> some View {
    content
      .keyboardType(includeDecimal ? .decimalPad : .numberPad)
      .onReceive(Just(text)) { newValue in
        var numbers = "0123456789"
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        if includeDecimal { numbers += decimalSeparator }
        if newValue.components(separatedBy: decimalSeparator).count-1 > 1 {
          let filtered = newValue
          self.text = String(filtered.dropLast())
        }
        else {
          let filtered = newValue.filter { numbers.contains($0) }
          if filtered != newValue { self.text = filtered }
        }
      }
  }
}

private extension View {
  func numbersOnly(_ text: Binding<String>, includeDecimal: Bool = false) -> some View {
    self.modifier(NumbersOnlyViewModifier(text: text, includeDecimal: includeDecimal))
  }
}

struct IngredientContextMenuPreview: View {
  let state: IngredientReducer.State
  
  var body: some View {
    HStack(alignment: .top) {
      
      // Checkbox
      Image(systemName: state.isComplete ? "checkmark.square" : "square")
        .fontWeight(.medium)
        .padding([.top], 2)
      
      // Name
      Text(!state.ingredient.name.isEmpty ? state.ingredient.name : "...")
        .lineLimit(1)
      
      Spacer()
      
      Rectangle()
        .fill(.clear)
        .frame(width: 50)
      
      // Amount
      Text(!state.ingredientAmountString.isEmpty ? state.ingredientAmountString : "...")
        .lineLimit(1)
      
      // Measurement
      Text(!state.ingredient.measure.isEmpty ? state.ingredient.measure : "...")
        .lineLimit(1)
    }
    .foregroundColor(state.isComplete ? .secondary : .primary)
    .accentColor(.accentColor)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      IngredientView(store: .init(
        initialState: .init(
          ingredient: Recipe.longMock.ingredientSections.first!.ingredients.first!
        ),
        reducer: IngredientReducer.init
      ))
      .padding()
    }
  }
}
