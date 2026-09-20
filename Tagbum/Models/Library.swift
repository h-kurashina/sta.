import Foundation

struct Album: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    var updatedAt = Date()
    var colorIndex = 0
}

struct Document: Identifiable, Codable, Equatable {
    var id = UUID()
    var albumId: UUID
    var imagePath: String
    var createdAt = Date()
    var order: Int
}

struct Library: Codable {
    var albums: [Album] = []
    var documents: [Document] = []
}
