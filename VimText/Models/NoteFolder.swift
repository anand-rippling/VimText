import Foundation

struct NoteFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "New Folder",
        icon: String = "folder",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }
}
