import SwiftUI
import ComposableArchitecture
import PhotosUI
import Log4swift

// TODO: Animation slide lag
// TODO: Maybe change order of adding a photo to next rather than inplace.
// TODO: Fix transition animation from 0 images to 1+ images

// MARK: - View
struct PhotosView: View {
  let store: StoreOf<PhotosReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
      let _ = Self._printChanges()
      Log4swift[Self.self].info("")

    return WithViewStore(store, observe: { $0 }) { viewStore in
      Rectangle()
        .fill(.clear)
        .aspectRatio(1.0, contentMode: .fit)
        .overlay {
          ZStack {
            ZStack {
              VStack {
                Rectangle()
                  .fill(.clear)
                  .aspectRatio(1, contentMode: .fit)
//                  .overlay(
//                    Image(systemName: "photo.stack")
//                      .resizable()
//                      .scaledToFill()
//                      .padding()
//                  )
                  .clipShape(Rectangle())
                
                  .foregroundColor(Color(uiColor: .systemGray4))
                  .padding()
              }
              .background(Color(uiColor: .systemGray6))
              .accentColor(.accentColor)
              .clipShape(RoundedRectangle(cornerRadius: 15))
              .opacity(viewStore.photos.isEmpty ? 1.0 : 0.0)
              
              ImageSliderView(
                imageDatas: viewStore.photos,
                selection: viewStore.$selection
              )
            }
            .blur(radius: viewStore.photoEditInFlight ? 5.0 : 0.0)
            .overlay {
              ProgressView()
                .opacity(viewStore.photoEditInFlight ? 1.0 : 0.0)
            }
            .disabled(viewStore.photoEditInFlight)
            
            // This allows the ability to disable all the actual logic when
            // a photo edit is in flight but bring the context menu to cancel.
            Color.clear
              .contentShape(Rectangle())
          }
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .if(!viewStore.disableContextMenu, transform: {
            $0.contextMenu(menuItems: {
              if viewStore.photoEditInFlight {
                Button {
                  viewStore.send(.cancelPhotoEdit, animation: .default)
                } label: {
                  Text("Cancel")
                }
              }
              if !viewStore.photoEditInFlight && !viewStore.photos.isEmpty {
                Button {
                  viewStore.send(.replaceButtonTapped, animation: .default)
                } label: {
                  Text("Replace")
                }
                .disabled(viewStore.photoEditInFlight)
              }
              
              // MARK: - DO NOT DELETE THE COMMENTED CODE:
              // There was a bug where a computed property didn't work or maybe <1
              // Test to make sure that the computed property works,
              //              let addButtonIsShowing.addButtonIsShowing: Bool = {
              //                if viewStore.photoEditInFlight { return false }
              //                if viewStore.supportSinglePhotoOnly {
              //                  return viewStore.photos.count < 1
              //                }
              //                else { return true }
              //              }()
              if viewStore.addButtonIsShowing {
                Button {
                  viewStore.send(.addButtonTapped, animation: .default)
                } label: {
                  Text("Add")
                }
                .disabled(viewStore.photoEditInFlight)
              }
              
              if !viewStore.photoEditInFlight && !viewStore.photos.isEmpty {
                Button(role: .destructive) {
                  viewStore.send(.deleteButtonTapped, animation: .default)
                } label: {
                  Text("Delete")
                }
                .disabled(viewStore.photoEditInFlight)
              }
            })
//            }, preview: {
//              PhotosView(store: store)
//                .frame(minWidth: 200, minHeight: 200)
//              // TODO: The context menu preview version of this view won't update in real-time...
//              // So we have to use the original view
//            })
          })
          .photosPicker(
            isPresented: viewStore.$photoPickerIsPresented,
            selection: viewStore.$photoPickerItem,
            matching: .images,
            preferredItemEncoding: .compatible,
            photoLibrary: .shared()
          )
          .alert(store: store.scope(state: \.$alert, action: PhotosReducer.Action.alert))
        }
    }
  }
}

// MARK: - CONDITONAL VIEWMODIFIER USE WITH EXTREME CAUTION.
/// This modifier is being used strictly for the context menu problem where we want to hide it or not.
/// Please do not use this anywhere else. Conditional view modifiers are notoriously buggy
/// because the the way SwiftUI animates. Use with extreme caution.
private extension View {
  /// Applies the given transform if the given condition evaluates to `true`.
  /// - Parameters:
  ///   - condition: The condition to evaluate.
  ///   - transform: The transform to apply to the source `View`.
  /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
  @ViewBuilder 
  func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
    if condition() {
      transform(self)
    } else {
      self
    }
  }
}

// MARK: - PhotosContextMenuPreview (deprecated)
// Does not refresh in time during inflight/real-time update of
// photos feature, thus is no longer used.
//private struct PhotosContextMenuPreview: View {
//  let state: PhotosReducer.State
//  @Environment(\.maxScreenWidth) var maxScreenWidth
//  
//  var body: some View {
//    VStack {
//      if state.photos.isEmpty {
//        VStack {
//          Image(systemName: "photo.stack")
//            .resizable()
//            .scaledToFit()
//            .frame(width: 75, height: 75)
//            .clipped()
//            .foregroundColor(Color(uiColor: .systemGray4))
//            .padding()
//          Text("Add Images")
//            .fontWeight(.bold)
//            .foregroundColor(Color(uiColor: .systemGray4))
//        }
//        .frame(width: maxScreenWidth.maxWidth, height: maxScreenWidth.maxWidth)
//        .background(.ultraThinMaterial)
//        .clipShape(RoundedRectangle(cornerRadius: 15))
//        .accentColor(.accentColor)
//      }
//      else  {
//        ImageSliderView(
//          imageDatas: state.photos,
//          selection: .constant(state.selection)
//        )
//      }
//    }
//  }
//}

private extension Image {
  func square() -> some View {
    Rectangle()
      .fill(.clear)
      .aspectRatio(1, contentMode: .fit)
      .overlay(
        self
          .resizable()
          .scaledToFill()
      )
      .clipShape(Rectangle())
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      PhotosView(store: .init(
        initialState: .init(
          photos: .init(Recipe.longMock.imageData.prefix(0)),
          supportSinglePhotoOnly: false,
          disableContextMenu: false
        ),
        reducer: PhotosReducer.init
      ))
    }
    .padding()
  }
}
