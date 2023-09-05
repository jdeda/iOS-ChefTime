import SwiftUI

struct FolderItemView: View {
  let folder: Folder
  let isEditing: Bool
  let isSelected: Bool
  @Environment(\.isHidingFolderImages) var isHidingFolderImages
  
  var body: some View {
    VStack {
      ZStack {
        Image(systemName: "folder.fill")
          .resizable()
          .scaledToFill()
          .padding()
          .background(.blue.opacity(0.15))
          .accentColor(.accentColor)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .opacity(isHidingFolderImages ? 1.0 : 0.0)
        
        ZStack {
          if let image = folder.recipes.first?.imageData.first?.image {
            image
              .resizable()
              .scaledToFill()
          }
          else {
            VStack {
              Image(systemName: "photo.stack")
                .resizable()
                .scaledToFit()
                .clipped()
                .foregroundColor(Color(uiColor: .systemGray4))
                .padding()
            }
            .background(Color(uiColor: .systemGray6))
            .accentColor(.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 15))
          }
        }
        .opacity(!isHidingFolderImages ? 1.0 : 0.0)
      }
      .scaledToFit()
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .overlay(alignment: .bottom) {
        if isEditing {
          ZStack(alignment: .bottom) {
            let width: CGFloat = 20
            if isSelected {
              ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 15)
                  .stroke(Color.accentColor, lineWidth: 5)
                
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
      
      Text(folder.name)
        .lineLimit(2)
        .font(.title3)
        .fontWeight(.bold)
      Text("\(folder.recipes.count) recipes")
        .lineLimit(2)
        .font(.body)
        .foregroundColor(.secondary)
      Spacer()
    }
  }
}

struct FolderItemView_Previews: PreviewProvider {
  static var previews: some View {
    FolderItemView(folder: Folder.shortMock, isEditing: true, isSelected: true)
  }
}

//import SwiftUI
//
//struct FolderItemView: View {
//  let folder: Folder
//  let isEditing: Bool
//  let isSelected: Bool
//  @Environment(\.isHidingFolderImages) var isHidingFolderImages
//
//  var body: some View {
//    VStack {
//      Group {
//        if isHidingFolderImages {
//          ZStack {
//            ImageData(
//              id: .init(),
//              data: (try? Data(contentsOf: Bundle.main.url(forResource: "folder_light", withExtension: "png")!))!
//            )!.image
//              .resizable()
//              .scaledToFill()
//              .padding()
//          }
//          .background(.blue.opacity(0.15))
//          .accentColor(.accentColor)
//          .clipShape(RoundedRectangle(cornerRadius: 15))
//        }
//        else {
//          if let image = folder.recipes.first?.imageData.first?.image {
//            image
//              .resizable()
//              .scaledToFill()
//          }
//          else {
//            VStack {
//              Image(systemName: "photo.stack")
//                .resizable()
//                .scaledToFit()
//                .clipped()
//                .foregroundColor(Color(uiColor: .systemGray4))
//                .padding()
//            }
//            .background(Color(uiColor: .systemGray6))
//            .accentColor(.accentColor)
//            .clipShape(RoundedRectangle(cornerRadius: 15))
//          }
//        }
//      }
//      .scaledToFit()
//      .clipShape(RoundedRectangle(cornerRadius: 15))
//      .overlay(alignment: .bottom) {
//        if isEditing {
//          ZStack(alignment: .bottom) {
//            let width: CGFloat = 20
//            if isSelected {
//              ZStack(alignment: .bottom) {
//                RoundedRectangle(cornerRadius: 15)
//                  .stroke(Color.accentColor, lineWidth: 5)
//
//                Circle()
//                  .fill(.primary)
//                  .colorInvert()
//                  .frame(width: width, height: width)
//                  .overlay {
//                    Image(systemName: "checkmark.circle")
//                      .resizable()
//                      .frame(width: width, height: width)
//                      .foregroundColor(.accentColor)
//                  }
//                  .padding(.bottom)
//              }
//            }
//            else {
//              Image(systemName: "circle")
//                .frame(width: width, height: width)
//                .foregroundColor(.secondary)
//                .padding(.bottom)
//            }
//          }
//        }
//      }
//
//      Text(folder.name)
//        .lineLimit(2)
//        .font(.title3)
//        .fontWeight(.bold)
//      Text("\(folder.recipes.count) recipes")
//        .lineLimit(2)
//        .font(.body)
//      Spacer()
//    }
//  }
//}
//
//struct FolderItemView_Previews: PreviewProvider {
//  static var previews: some View {
//    FolderItemView(folder: Folder.shortMock, isEditing: true, isSelected: true)
//  }
//}



//import SwiftUI
//
//struct FolderItemView: View {
//  let folder: Folder
//  let isEditing: Bool
//  let isSelected: Bool
//  @Environment(\.isHidingFolderImages) var isHidingFolderImages
//
//  var body: some View {
//    VStack {
//      Group {
//        if isHidingFolderImages {
//          ZStack {
//            ImageData(
//              id: .init(),
//              data: (try? Data(contentsOf: Bundle.main.url(forResource: "folder_light", withExtension: "png")!))!
//            )!.image
//              .resizable()
//              .scaledToFill()
//              .padding()
//          }
//          .background(.blue.opacity(0.15))
//          .accentColor(.accentColor)
//          .clipShape(RoundedRectangle(cornerRadius: 15))
//        }
//        else {
//          if let image = folder.recipes.first?.imageData.first?.image {
//            image
//              .resizable()
//              .scaledToFill()
//          }
//          else {
//            VStack {
//              Image(systemName: "photo.stack")
//                .resizable()
//                .scaledToFit()
//                .clipped()
//                .foregroundColor(Color(uiColor: .systemGray4))
//                .padding()
//            }
//            .background(Color(uiColor: .systemGray6))
//            .accentColor(.accentColor)
//            .clipShape(RoundedRectangle(cornerRadius: 15))
//          }
//        }
//      }
//      .scaledToFit()
//      .clipShape(RoundedRectangle(cornerRadius: 15))
//      .overlay(alignment: .bottom) {
//        if isEditing {
//          ZStack(alignment: .bottom) {
//            let width: CGFloat = 20
//            if isSelected {
//              ZStack(alignment: .bottom) {
//                RoundedRectangle(cornerRadius: 15)
//                  .stroke(Color.accentColor, lineWidth: 5)
//
//                Circle()
//                  .fill(.primary)
//                  .colorInvert()
//                  .frame(width: width, height: width)
//                  .overlay {
//                    Image(systemName: "checkmark.circle")
//                      .resizable()
//                      .frame(width: width, height: width)
//                      .foregroundColor(.accentColor)
//                  }
//                  .padding(.bottom)
//              }
//            }
//            else {
//              Image(systemName: "circle")
//                .frame(width: width, height: width)
//                .foregroundColor(.secondary)
//                .padding(.bottom)
//            }
//          }
//        }
//      }
//
//      Text(folder.name)
//        .lineLimit(2)
//        .font(.title3)
//        .fontWeight(.bold)
//      Text("\(folder.recipes.count) recipes")
//        .lineLimit(2)
//        .font(.body)
//      Spacer()
//    }
//  }
//}
//
//struct FolderItemView_Previews: PreviewProvider {
//  static var previews: some View {
//    FolderItemView(folder: Folder.shortMock, isEditing: true, isSelected: true)
//  }
//}

//import SwiftUI
//
//struct FolderItemView: View {
//  let folder: Folder
//  let isEditing: Bool
//  let isSelected: Bool
//  @Environment(\.isHidingFolderImages) var isHidingFolderImages
//
//  var body: some View {
//    VStack {
//      Group {
//        if isHidingFolderImages {
//          ZStack {
//            ImageData(
//              id: .init(),
//              data: (try? Data(contentsOf: Bundle.main.url(forResource: "folder_light", withExtension: "png")!))!
//            )!.image
//              .resizable()
//              .scaledToFill()
//              .padding()
//          }
//          .background(.blue.opacity(0.15))
//          .accentColor(.accentColor)
//          .clipShape(RoundedRectangle(cornerRadius: 15))
//        }
//        else {
//          if let image = folder.recipes.first?.imageData.first?.image {
//            image
//              .resizable()
//              .scaledToFill()
//          }
//          else {
//            VStack {
//              Image(systemName: "photo.stack")
//                .resizable()
//                .scaledToFit()
//                .clipped()
//                .foregroundColor(Color(uiColor: .systemGray4))
//                .padding()
//            }
//            .background(Color(uiColor: .systemGray6))
//            .accentColor(.accentColor)
//            .clipShape(RoundedRectangle(cornerRadius: 15))
//          }
//        }
//      }
//      .scaledToFit()
//      .clipShape(RoundedRectangle(cornerRadius: 15))
//      .overlay(alignment: .bottom) {
//        if isEditing {
//          ZStack(alignment: .bottom) {
//            let width: CGFloat = 20
//            if isSelected {
//              ZStack(alignment: .bottom) {
//                RoundedRectangle(cornerRadius: 15)
//                  .stroke(Color.accentColor, lineWidth: 5)
//
//                Circle()
//                  .fill(.primary)
//                  .colorInvert()
//                  .frame(width: width, height: width)
//                  .overlay {
//                    Image(systemName: "checkmark.circle")
//                      .resizable()
//                      .frame(width: width, height: width)
//                      .foregroundColor(.accentColor)
//                  }
//                  .padding(.bottom)
//              }
//            }
//            else {
//              Image(systemName: "circle")
//                .frame(width: width, height: width)
//                .foregroundColor(.secondary)
//                .padding(.bottom)
//            }
//          }
//        }
//      }
//
//      Text(folder.name)
//        .lineLimit(2)
//        .font(.title3)
//        .fontWeight(.bold)
//      Text("\(folder.recipes.count) recipes")
//        .lineLimit(2)
//        .font(.body)
//      Spacer()
//    }
//  }
//}
//
//struct FolderItemView_Previews: PreviewProvider {
//  static var previews: some View {
//    FolderItemView(folder: Folder.shortMock, isEditing: true, isSelected: true)
//  }
//}
