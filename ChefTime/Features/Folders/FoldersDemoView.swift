import SwiftUI
import ComposableArchitecture

// MARK: - View
struct FolderView1: View {
  let store: StoreOf<FolderDemoReducer>
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        ScrollView {
          
        }
        .navigationTitle(viewStore.folder.name)
      }
    }
  }
}

//HStack {
//  Image(systemName: "folder.fill")
//  Text(folder.name)
//}

// MARK: - View
struct FolderView2: View {
  let store: StoreOf<FolderDemoReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        ScrollView {
          LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewStore.folder.recipes) { recipe in
              RecipeGridItemView(recipe: recipe)
            }
            .navigationTitle("Recipes")
          }
          .padding()
        }
        .navigationTitle(viewStore.folder.name)
      }
    }
  }
  
  struct RecipeGridItemView: View {
    let width = UIScreen.main.bounds.width * 0.40
    let recipe: Recipe
    
    var body: some View {
      VStack {
        recipe.imageData.first?.image
          .resizable()
          .frame(width: width, height: width)
          .clipShape(RoundedRectangle(cornerRadius: 15))
        
        Text(recipe.name)
          .lineLimit(2)
          .font(.title3)
          .fontWeight(.bold)
        Text("Delicious!")
          .lineLimit(2)
          .font(.body)
        Spacer()
      }
      .frame(maxWidth: width)
    }
  }
}

// MARK: - View
struct FolderView3: View {
  let store: StoreOf<FolderDemoReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        ScrollView {
          LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewStore.folder.recipes) { recipe in
              RecipeGridItemView(recipe: recipe)
            }
          }
          .padding()
        }
        .navigationTitle(viewStore.folder.name)
      }
    }
  }
  
  struct RecipeGridItemView: View {
    let width = UIScreen.main.bounds.width * 0.40
    let recipe: Recipe
    
    var body: some View {
      ZStack {
        Color(uiColor: .systemGray2)
        
        VStack {
          recipe.imageData.first?.image
            .resizable()
            .frame(width: width, height: width)
          
          Text(recipe.name)
            .lineLimit(2)
            .padding(.horizontal)
            .colorInvert()
          
          Spacer()
        }
      }
      .frame(maxWidth: width)
      .clipShape(RoundedRectangle(cornerRadius: 15))
    }
  }
}

// MARK: - View
struct FolderView4: View {
  let store: StoreOf<FolderDemoReducer>
  let columns: [GridItem] = [.init(), .init()]
  @Environment(\.maxScreenWidth) var maxScreenWidth
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        List {
          ForEach(viewStore.folder.recipes) { recipe in
            RecipeRowtemView(recipe: recipe)
          }
          .listRowSeparator(.visible, edges: .bottom)
          .listRowInsets(.some(.init(top: 15, leading: 15, bottom: 15, trailing: 15)))
        }
        .listStyle(.plain)
        .navigationTitle(viewStore.folder.name)
      }
    }
  }
  
  struct RecipeRowtemView: View {
    let width = UIScreen.main.bounds.width * 0.30
    let recipe: Recipe
    
    var body: some View {
      HStack {
        recipe.imageData.first?.image
          .resizable()
        //          .scaledToFill()
          .frame(width: width, height: width)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .padding([.trailing], 10)
        VStack(alignment: .leading) {
          Text(recipe.name)
            .lineLimit(3)
            .font(.title3)
            .fontWeight(.bold)
          Text("Delicious!")
            .lineLimit(3)
            .font(.body)
          Spacer()
        }
        Spacer()
      }
      .frame(height: width)
      .navigationTitle("Recipes")
    }
  }
  
}

// MARK: - Reducer
struct FolderDemoReducer: Reducer {
  struct State: Equatable {
    var folder: Folder
  }
  
  enum Action: Equatable {
    
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      }
    }
  }
}

// MARK: - Preview
struct FolderDemoReducer_Previews: PreviewProvider {
  static var previews: some View {
    FolderView1(store: .init(
      initialState: .init(
        folder: .longMock
      ),
      reducer: FolderDemoReducer.init
    ))
    
    FolderView2(store: .init(
      initialState: .init(
        folder: .longMock
      ),
      reducer: FolderDemoReducer.init
    ))
    
    FolderView3(store: .init(
      initialState: .init(
        folder: .longMock
      ),
      reducer: FolderDemoReducer.init
    ))
    
    FolderView4(store: .init(
      initialState: .init(
        folder: .longMock
      ),
      reducer: FolderDemoReducer.init
    ))
  }
}

