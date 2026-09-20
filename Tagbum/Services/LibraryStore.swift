import SwiftUI

@MainActor @Observable
final class LibraryStore {
    private(set) var library = Library()
    var errorMessage: String?
    private(set) var loadFailed = false
    let root: URL

    init(root: URL? = nil) {
        self.root = root ?? URL.applicationSupportDirectory.appending(path: "Tagbum", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: self.root, withIntermediateDirectories: true)
            let url = self.root.appending(path: "library.json")
            if FileManager.default.fileExists(atPath: url.path) {
                library = try JSONDecoder().decode(Library.self, from: Data(contentsOf: url))
            }
        } catch {
            loadFailed = true
            errorMessage = "保存済みの資料を読み込めませんでした。データを保護するため、アプリを再起動してください。\n\(error.localizedDescription)"
        }
    }

    var albums: [Album] { library.albums }
    func documents(in albumID: UUID) -> [Document] {
        library.documents.filter { $0.albumId == albumID }.sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.order < $1.order
        }
    }
    func album(_ id: UUID) -> Album? { albums.first { $0.id == id } }
    func url(for document: Document) -> URL { root.appending(path: document.imagePath) }

    @discardableResult
    private func commit(_ next: Library) -> Bool {
        guard !loadFailed else { return false }
        do {
            try JSONEncoder().encode(next).write(to: root.appending(path: "library.json"), options: .atomic)
            library = next
            return true
        } catch {
            errorMessage = "保存できませんでした。空き容量を確認して、もう一度お試しください。\n\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func saveAlbum(name: String, editing: Album? = nil) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        var next = library
        if let editing, let index = next.albums.firstIndex(where: { $0.id == editing.id }) {
            next.albums[index].name = name
            next.albums[index].updatedAt = Date()
        } else {
            next.albums.append(Album(name: name, colorIndex: next.albums.count % 4))
        }
        return commit(next)
    }

    @discardableResult
    func deleteAlbum(_ album: Album) -> Bool {
        let removed = documents(in: album.id)
        var next = library
        next.albums.removeAll { $0.id == album.id }
        next.documents.removeAll { $0.albumId == album.id }
        guard commit(next) else { return false }
        removeFiles(removed)
        return true
    }

    @discardableResult
    func deleteDocument(_ document: Document) -> Bool {
        var next = library
        next.documents.removeAll { $0.id == document.id }
        if let index = next.albums.firstIndex(where: { $0.id == document.albumId }) {
            next.albums[index].updatedAt = Date()
        }
        guard commit(next) else { return false }
        removeFiles([document])
        return true
    }

    func addImages(_ data: [Data], to albumID: UUID) async -> Bool {
        guard !loadFailed, album(albumID) != nil, !data.isEmpty else { return false }
        do {
            let paths = try await ImageStorage.shared.write(data, root: root)
            guard album(albumID) != nil else {
                for path in paths { try? FileManager.default.removeItem(at: root.appending(path: path)) }
                return false
            }
            let date = Date()
            let documents = paths.enumerated().map {
                Document(albumId: albumID, imagePath: $0.element, createdAt: date, order: $0.offset)
            }
            var next = library
            next.documents.append(contentsOf: documents)
            if let index = next.albums.firstIndex(where: { $0.id == albumID }) { next.albums[index].updatedAt = date }
            guard commit(next) else { removeFiles(documents); return false }
            return true
        } catch {
            errorMessage = "画像を保存できませんでした。\n\(error.localizedDescription)"
            return false
        }
    }

    private func removeFiles(_ documents: [Document]) {
        for document in documents { try? FileManager.default.removeItem(at: url(for: document)) }
    }
}
