import XCTest
import ComposableArchitecture
import Dependencies
import SwiftData

@testable import ChefTime

@MainActor
final class SDClientTests_Folder: XCTestCase {
  func testInit() async {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    let recipes = await sdc.retrieveFolders()
    XCTAssertTrue(folders.isEmpty)
    XCTAssertTrue(recipes.isEmpty)
  }
  
  // TODO: Runtime performance slow (2-3 seconds)
  func testCreateFolder() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    XCTAssertTrue(folders.isEmpty)
    
    let dateGenerator = DateGenerator({ Date() })
    
    // Let's add an empty butter folder.
    let folder = Folder(id: .init(), name: "Butter", creationDate: dateGenerator(), lastEditDate: dateGenerator())
    try await sdc.createFolder(folder)
    let newFolders = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders.count == 1)
    XCTAssertTrue(newFolders.first == folder)
    
    // Let's add a complicated folder:
    let folder2 = Folder.longMock
    try await sdc.createFolder(folder2)
    let newFolders2 = await sdc.retrieveFolders()
    print("FDC", foldersCount(newFolders2))
    XCTAssertTrue(foldersCount(newFolders2) == 12) // TODO: Magic number.
    XCTAssertEqual(folder, try XCTUnwrap(newFolders2.first(where: { $0.id == folder.id })))
    XCTAssertEqual(folder2, try XCTUnwrap(newFolders2.first(where: { $0.id == folder2.id })))
  }
  
  func testCreateDupeFolder1() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    XCTAssertTrue(folders.isEmpty)
    
    let dateGenerator = DateGenerator({ Date() })
    
    // Let's add an empty butter folder.
    let folder = Folder(id: .init(), name: "Butter", creationDate: dateGenerator(), lastEditDate: dateGenerator())
    try await sdc.createFolder(folder)
    let newFolders = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders.count == 1)
    XCTAssertTrue(newFolders.first == folder)
    
    // Lets try to add it again (dupe)
    do {
      try await sdc.createFolder(folder)
      XCTFail("Should have thrown an error!")
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.duplicate)
    }
    let newFolders2 = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders2.count == 1)
    XCTAssertTrue(newFolders2.first == folder)
  }
  
  func testCreateDupeFolder2() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    XCTAssertTrue(folders.isEmpty)
    
    let dateGenerator = DateGenerator({ Date() })
    
    // Let's add an empty butter folder.
    let folder1 = Folder(id: .init(), name: "Butter", creationDate: dateGenerator(), lastEditDate: dateGenerator())
    try await sdc.createFolder(folder1)
    let newFolders1 = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders1.count == 1)
    XCTAssertTrue(newFolders1.first == folder1)
    
    // Lets try to add it again (dupe)
    do {
      try await sdc.createFolder(folder1)
      XCTFail("Should have thrown an error!")
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.duplicate)
    }
    let newFolders1D = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders1D.count == 1)
    XCTAssertTrue(newFolders1D.first == folder1)
    
    // Let's add an empty bread folder.
    let folder2 = Folder(id: .init(), name: "Bread", creationDate: dateGenerator(), lastEditDate: dateGenerator())
    try await sdc.createFolder(folder2)
    let newFolders2 = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders2.count == 2)
    XCTAssertTrue(newFolders2.first(where: {$0.id == folder2.id}) == folder2)
    XCTAssertTrue(newFolders2.first(where: {$0.id == folder1.id}) == folder1)
    
    // Lets try to add it again (dupe)
    do {
      try await sdc.createFolder(folder2)
      XCTFail("Should have thrown an error!")
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.duplicate)
    }
    let newFolders2D = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders2D.count == 2)
    XCTAssertTrue(newFolders2D.first(where: {$0.id == folder2.id}) == folder2)
    XCTAssertTrue(newFolders2D.first(where: {$0.id == folder1.id}) == folder1)
    
    // Now put the bread folder into the butter folder and see if that causes any dupe problem.
    // Same ID should update the same folder and or interact with dupes the same way.
    var folder1Updated = folder1
    folder1Updated.folders.append(folder2)
    do {
      try await sdc.createFolder(folder1Updated)
      XCTFail("Should have thrown an error!")
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.duplicate)
    }
    let newFolders3D = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders3D.count == 2)
    XCTAssertTrue(newFolders3D.first(where: {$0.id == folder2.id}) == folder2)
    XCTAssertTrue(newFolders3D.first(where: {$0.id == folder1.id}) == folder1)
    
    // Instead of creating try to update it.
    do {
      try await sdc.updateFolder(folder1Updated)
      XCTFail("Should have thrown an error!")
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.duplicate)
    }
    let newFolders4D = await sdc.retrieveFolders()
    XCTAssertTrue(newFolders4D.count == 2)
    XCTAssertTrue(newFolders4D.first(where: {$0.id == folder2.id}) == folder2)
    XCTAssertTrue(newFolders4D.first(where: {$0.id == folder1.id}) == folder1)
  }
  
  func testUpdateFolder() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    XCTAssertTrue(folders.isEmpty)
    
    let date = DateGenerator({ Date() })

    
    // Let's add an empty butter folder.
    var folder = Folder(id: .init(), name: "Butter", creationDate: date(), lastEditDate: date())
    try await sdc.createFolder(folder)
    let folderSDC1 = await sdc.retrieveFolders().first
    XCTAssertEqual(folder, folderSDC1)
    
    // Edit the folder and update it to the DB.
    folder.name = "Burger Recipes"
    try await sdc.updateFolder(folder)
    let folderSDC2 = await sdc.retrieveFolders().first
    XCTAssertEqual(folder, folderSDC2)
    
    // Repeat.
    var childFolderA = Folder(id: .init(), name: "All American Burgers", creationDate: date(), lastEditDate: date())
    childFolderA.recipes.append(.longMock)
    folder.folders.append(childFolderA)
    folder.name = "Burgers"
    try await sdc.updateFolder(folder)
    let foldersSDC3 = await sdc.retrieveFolders()
    XCTAssertEqual(foldersSDC3.count, 2)
    XCTAssertEqual(childFolderA, foldersSDC3.first(where: {$0.id == childFolderA.id})!)
    XCTAssertEqual(folder, foldersSDC3.first(where: {$0.id == folder.id})!)
    let recipesSDC3 = await sdc.retrieveRecipes()
    XCTAssertEqual(recipesSDC3.count, 1)
    XCTAssertEqual(folder.folders.first!.recipes.first!, recipesSDC3.first!)

    
    // Repeat
    folder.lastEditDate = date()
    let firstFolderFirstRecipe = Recipe(id: .init(), name: "BBQ Burger", creationDate: date(), lastEditDate: date())
    folder.recipes.append(firstFolderFirstRecipe)
    try await sdc.updateFolder(folder)
    let foldersSDC4 = await sdc.retrieveFolders()
    XCTAssertEqual(foldersSDC4.count, 2)
    XCTAssertEqual(childFolderA, foldersSDC4.first(where: {$0.id == childFolderA.id})!)
    XCTAssertEqual(folder, foldersSDC4.first(where: {$0.id == folder.id})!)
    let recipesSDC4 = await sdc.retrieveRecipes()
    XCTAssertEqual(recipesSDC4.count, 2)
    XCTAssertEqual(firstFolderFirstRecipe, recipesSDC4.first(where: {$0.id == firstFolderFirstRecipe.id}))
    XCTAssertEqual(folder.recipes.first!, recipesSDC4.first(where: {$0.id == folder.recipes.first!.id}))
    
        
    childFolderA.recipes.removeAll()
    folder.recipes.remove(id: firstFolderFirstRecipe.id)
    folder.folders[id: childFolderA.id]!.recipes.removeAll()
    folder.lastEditDate = date()
    try await sdc.updateFolder(folder)
    let foldersSDC5 = await sdc.retrieveFolders()
    XCTAssertEqual(foldersSDC4.count, 2)
    XCTAssertEqual(childFolderA, foldersSDC5.first(where: {$0.id == childFolderA.id})!)
    XCTAssertEqual(folder, foldersSDC5.first(where: {$0.id == folder.id})!)
    let recipesSDC5 = await sdc.retrieveRecipes()
    XCTAssertTrue(recipesSDC5.isEmpty)
  }

  func testUpdateFolderInvalidID() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let folders = await sdc.retrieveFolders()
    XCTAssertTrue(folders.isEmpty)
    
    let date = DateGenerator({ Date() })

    // Let's add an empty butter folder.
    let id = Folder.ID()
    var folder = Folder(id: id, name: "Butter", creationDate: date(), lastEditDate: date())
    try await sdc.createFolder(folder)
    let folderSDC1 = await sdc.retrieveFolder(folder.id)
    XCTAssertEqual(folder, folderSDC1)
    
    // Delete it.
    try await sdc.deleteFolder(folder.id)

    // Try to update the folder.
    folder.name = "Butter Recipes"
    do {
      try await sdc.updateFolder(folder)
      XCTFail("Should have thrown an error!")
    } catch {
      XCTAssertEqual(error as? SDClient.SDError, SDClient.SDError.notFound)
    }
    let folderSDC2 = await sdc.retrieveFolder(folder.id)
    XCTAssertNil(folderSDC2)
  }

  func deleteFolder() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let initfolders = await sdc.retrieveFolders()
    XCTAssertTrue(initfolders.isEmpty)
    
    let date = DateGenerator({ Date() })
    
    // Let's create some folders and add them.
    let folders: [Folder] = (1...10).map {
      .init(id: .init(), name: "Folder No. \($0)", creationDate: date(), lastEditDate: date())
    }
    for folder in folders {
      try await sdc.createFolder(folder)
    }
    let folders1 = await sdc.retrieveFolders()
    XCTAssertEqual(folders1, folders)
    XCTAssertTrue(folders1.count == 9)
    XCTAssertTrue(folders.count == 9)
    
    // Let's delete one and check.
    try await sdc.deleteFolder(folders1.first!.id)
    let folders2SDC = await sdc.retrieveFolders()
    var folders2 = folders1
    folders2.removeLast()
    XCTAssertEqual(folders2SDC, folders2)
    XCTAssertTrue(folders2SDC.count == 8)
    XCTAssertTrue(folders2.count == 8)
    
    // Repeat.
    try await sdc.deleteFolder(folders2.first!.id)
    let folders3SDC = await sdc.retrieveFolders()
    var folders3 = folders2
    folders3.removeLast()
    XCTAssertEqual(folders3SDC, folders3)
    XCTAssertTrue(folders3SDC.count == 7)
    XCTAssertTrue(folders3.count == 7)
    
    // Repeat.
    try await sdc.deleteFolder(folders3[1].id)
    let folders4SDC = await sdc.retrieveFolders()
    var folders4 = folders3
    folders4.remove(at: 1)
    XCTAssertEqual(folders4SDC, folders4)
    XCTAssertTrue(folders4SDC.count == 6)
    XCTAssertTrue(folders4.count == 6)
    
    // Delete the rest.
    for folder in folders3 {
      try await sdc.deleteFolder(folder.id)
    }
    let folders5SDC = await sdc.retrieveFolders()
    XCTAssertTrue(folders5SDC.isEmpty)
  }
  
  func testCRUDLargeFolder() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "/dev/null"))!
    let initfolders = await sdc.retrieveFolders()
    XCTAssertTrue(initfolders.isEmpty)
    
    let date = DateGenerator({ Date() })
    
    let f1 = Folder.longMock
    try await sdc.createFolder(f1)
    let foldersSDC = await sdc.retrieveFolders()
    XCTAssertEqual(foldersSDC.count, 6) // MARK: - Magic Number
    XCTAssertEqual(foldersSDC.first(where: {$0.id == f1.id})!, f1)
  }
  // TODO: What happens if you create a folder with a unique recipe ID/childID you're doomed
}

// MARK: - FolderCount helpers. Helps calculate the folder count since folders can be recursive.
extension SDClientTests_Folder {
  private func folderCount(_ folder: Folder) -> Int {
    folder.folders.reduce(into: folder.folders.count) { partial, folder in
      partial += folderCount(folder)
    }
  }
  
  private func foldersCount(_ folders: [Folder]) -> Int {
    folders.reduce(into: folders.count) { partial, folder in
      partial += folderCount(folder)
    }
  }
}
