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
        Section {
          DisclosureGroup(isExpanded: viewStore.$foldersIsExpanded) {
            LazyVGrid(columns: columns, spacing: 10) {
              ForEach(viewStore.folder.folders) { folder in
                let image = folder.recipes.first?.imageData.first?.image ?? Image(systemName: "folder")
                GridItemView(
                  image: image,
                  title: folder.name,
                  subTitle: "Foo"
                )
                .onTapGesture { viewStore.send(.delegate(.folderTapped(folder.id))) }
              }
            }
          } label: {
            Text("Folders")
              .textTitleStyle()
            Spacer()
          }
          .accentColor(.primary)
          .disclosureGroupStyle(CustomDisclosureGroupStyle())
        }
        .padding(.horizontal)
        
        // Recipes.
        Section {
          DisclosureGroup(isExpanded: viewStore.$recipesIsExpanded) {
            LazyVGrid(columns: columns, spacing: 10) {
              ForEach(viewStore.folder.recipes) { recipe in
                let image = recipe.imageData.first?.image ?? Image(systemName: "folder")
                GridItemView(
                  image: image,
                  title: recipe.name,
                  subTitle: "Foo"
                )
                .onTapGesture { viewStore.send(.delegate(.recipeTapped(recipe.id))) }
              }
            }
          } label: {
            Text("Recipes")
              .textTitleStyle()
            Spacer()
          }
          .disclosureGroupStyle(CustomDisclosureGroupStyle())
          .accentColor(.primary)
        }
        .padding(.horizontal)
      }
      .navigationTitle(viewStore.folder.name)
      .searchable(
        text: .constant(""),
        placement: .navigationBarDrawer(displayMode: .always)
      )
    }
  }
  
  struct GridItemView: View {
    let width = UIScreen.main.bounds.width * 0.40
    let image: Image
    let title: String
    let subTitle: String
    
    var body: some View {
      VStack {
        self.image
          .resizable()
          .frame(width: width, height: width)
          .clipShape(RoundedRectangle(cornerRadius: 15))
        Text(self.title)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text(self.subTitle)
          .lineLimit(2)
          .font(.body)
        Spacer()
      }
      .frame(maxWidth: width)
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

