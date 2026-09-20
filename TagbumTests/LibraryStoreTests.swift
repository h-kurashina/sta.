import XCTest
@testable import Tagbum

@MainActor
final class LibraryStoreTests: XCTestCase {
    func testPersistenceOrderIsolationAndDeletion() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(root: root)
        XCTAssertTrue(store.saveAlbum(name: "  物理学  "))
        XCTAssertTrue(store.saveAlbum(name: "数学"))
        let physics = try XCTUnwrap(store.albums.first)
        let maths = try XCTUnwrap(store.albums.last)
        XCTAssertEqual(physics.name, "物理学")
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).jpegData(withCompressionQuality: 0.8) { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        let saved = await store.addImages([image, image, image], to: physics.id)
        XCTAssertTrue(saved)
        XCTAssertEqual(store.documents(in: physics.id).map(\.order), [0, 1, 2])
        XCTAssertTrue(store.documents(in: maths.id).isEmpty)
        let reloaded = LibraryStore(root: root)
        XCTAssertEqual(reloaded.documents(in: physics.id).count, 3)
        XCTAssertTrue(reloaded.saveAlbum(name: "力学", editing: physics))
        XCTAssertEqual(LibraryStore(root: root).album(physics.id)?.name, "力学")
        let document = try XCTUnwrap(reloaded.documents(in: physics.id).first)
        let url = reloaded.url(for: document)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(reloaded.deleteDocument(document))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(reloaded.deleteAlbum(physics))
        XCTAssertTrue(LibraryStore(root: root).documents(in: physics.id).isEmpty)
        XCTAssertEqual(LibraryStore(root: root).albums.count, 1)
    }

    func testInvalidImageRollsBackAndCorruptLibraryIsProtected() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(root: root)
        XCTAssertFalse(store.saveAlbum(name: " \n"))
        store.saveAlbum(name: "英語")
        let album = try XCTUnwrap(store.albums.first)
        let saved = await store.addImages([Data("invalid".utf8)], to: album.id)
        XCTAssertFalse(saved)
        XCTAssertTrue(store.documents(in: album.id).isEmpty)
        let metadata = root.appending(path: "library.json")
        let corrupt = Data("broken json".utf8)
        try corrupt.write(to: metadata)
        let protected = LibraryStore(root: root)
        XCTAssertTrue(protected.loadFailed)
        XCTAssertFalse(protected.saveAlbum(name: "新規"))
        XCTAssertEqual(try Data(contentsOf: metadata), corrupt)
    }
}
