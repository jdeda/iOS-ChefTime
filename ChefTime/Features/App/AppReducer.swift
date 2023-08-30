import SwiftUI

struct AppView: View {
  var body: some View {
    NavigationStack {
      FoldersView(store: .init(
        initialState: .init(userFolders: .init(uniqueElements: Folder.longMock.folders)),
        reducer: FoldersReducer.init
      ))
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView()
  }
}
