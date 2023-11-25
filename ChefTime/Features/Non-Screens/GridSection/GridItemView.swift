import ComposableArchitecture
import SwiftUI

struct GridItemView<ID: Equatable & Hashable>: View {
  let store: StoreOf<GridItemReducer<ID>>
  let isEditing: Bool
  let isSelected: Bool
  @Environment(\.isHidingImages) var isHidingImages
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        ZStack {
          
          // TODO: Why are there PhotosViews here???
          PhotosView(store: store.scope(state: \.photos, action: { .photos($0) }))
            .opacity(isHidingImages ? 0.0 : 1.0)
          
          PhotosView(store: .init(initialState: .init(photos: .init()), reducer: {}))
            .disabled(true)
            .opacity(!isHidingImages ? 0.0 : 1.0)
        }
        .overlay(alignment: .bottom) {
          if isEditing {
            ZStack(alignment: .bottom) {
              let width: CGFloat = 20
              if isSelected {
                ZStack(alignment: .bottom) {
                  RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.accentColor, lineWidth: 5)
                  
                  Circle()
                    .fill(.primary)
                    .colorInvert()
                    .frame(width: width, height: width)
                    .overlay {
                      Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: width, height: width)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.bottom)
                }
              }
              else {
                Image(systemName: "circle")
                  .frame(width: width, height: width)
                  .foregroundColor(.secondary)
                  .padding(.bottom)
              }
            }
          }
        }
        
        Text(viewStore.name)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text("Created 8/13/23")
          .lineLimit(2)
          .font(.body)
          .foregroundColor(.secondary)
      }
      .background(Color.primary.colorInvert())
      .clipShape(RoundedRectangle(cornerRadius: 15))
      
      .alert(
        store: store.scope(state: \.$destination, action: { .destination($0) }),
        state: \.alert,
        action: { .alert($0) }
      )
      .alert("Rename", isPresented: viewStore.binding(
        get: { $0.destination == .renameAlert },
        send: { _ in .destination(.dismiss) }
      )) {
        RenameAlert(name: viewStore.name) {
          viewStore.send(.renameAcceptButtonTapped($0), animation: .default)
        }
      }
      .contextMenu {
        Button {
          viewStore.send(.renameButtonTapped, animation: .default)
        } label: {
          Text("Rename")
        }
        Button {
          viewStore.send(.delegate(.move), animation: .default)
        } label: {
          Text("Move")
        }
        Button(role: .destructive) {
          viewStore.send(.deleteButtonTapped, animation: .default)
        } label: {
          Text("Delete")
        }
      }
    }
  }
}

// MARK: - AlertView
private struct RenameAlert: View {
  @State var name: String
  @FocusState private var isTextFieldFocused: Bool
  
  var submitName: (_ name: String) -> Void = unimplemented("RenameAlert.submitName")
  
  var body: some View {
    
    // MARK: - Runtime crash if textfield is wrapped in other views
    TextField("", text: $name)
      .onAppear { self.isTextFieldFocused = true } // MARK: - uncontrolled onAppear
      .focused($isTextFieldFocused)
    // ( •_•) This beautifully understandable block of code allows one to preselect the whole name (⁎❛ᴗ❛⁎ )
      .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
        if let textField = obj.object as? UITextField {
          textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
      }
    
    Button {
    } label: {
      Text("Cancel")
        .fontWeight(.bold) // MARK: - Alert ignores these style modifiers...
    }
    
    Button {
      submitName(name)
    } label: {
      Text("Save")
        .fontWeight(.medium) // MARK: - Alert ignores these style modifiers...
    }
  }
}

// MARK: - Preview
#Preview {
  NavigationStack {
    GridItemView<Recipe.ID>(
      store: .init(
        initialState: .init(
          id: Recipe.longMock.id,
          name: Recipe.longMock.name,
          imageData: Recipe.longMock.imageData
        ),
        reducer: GridItemReducer.init
      ),
      isEditing: false,
      isSelected: false
    )
    .padding(50)
    .onAppear {
      UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(.yellow)
    }
  }
}

