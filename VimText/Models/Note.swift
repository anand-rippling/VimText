import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var rtfData: Data?
    var folderId: UUID?
    var createdAt: Date
    var modifiedAt: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String = "New Note",
        content: String = "",
        rtfData: Data? = nil,
        folderId: UUID? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.rtfData = rtfData
        self.folderId = folderId
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isPinned = isPinned
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "New Note" : trimmed
    }

    var preview: String {
        let lines = content.components(separatedBy: .newlines)
        let previewLines = lines.prefix(3).joined(separator: " ")
        let trimmed = previewLines.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No additional text" : String(trimmed.prefix(120))
    }
}
