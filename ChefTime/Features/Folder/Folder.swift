import SwiftUI
import ComposableArchitecture

// TODO: standardize DisclosureGroupStyle accent color?

// MARK: - View
struct FolderView: View {
  let store: StoreOf<FolderReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        
      }
    }
  }
}

// MARK: - Reducer
struct FolderReducer: Reducer {
  struct State: Equatable {
    var folder: Folder
    @BindingState var foldersIsExpanded: Bool = true
    @BindingState var recipesIsExpanded: Bool = true
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case delegate(DelegateAction)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding, .delegate:
        return .none
      }
    }
  }
}

extension FolderReducer {
  enum DelegateAction: Equatable {
    case folderTapped(Folder.ID)
    case recipeTapped(Recipe.ID)
  }
}

// MARK: - Preview
struct FolderView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      FolderView(store: .init(
        initialState: .init(
          folder: .longMock
        ),
        reducer: FolderReducer.init
      ))
    }
  }
}

