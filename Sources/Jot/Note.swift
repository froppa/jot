import Foundation
import SwiftData

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var project: String
    var isPinned: Bool
    var reminderAt: Date?
    var colorName: String

    init(
        text: String,
        project: String,
        isPinned: Bool = false,
        reminderAt: Date? = nil,
        colorName: String = NoteColor.indigo.rawValue,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.text = text
        self.project = project
        self.isPinned = isPinned
        self.reminderAt = reminderAt
        self.colorName = colorName
        self.createdAt = createdAt
    }

    var title: String {
        let firstLine = text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? "Untitled note"
        return String(firstLine.prefix(48))
    }

    var preview: String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count > 1 else { return "" }
        return String(lines.dropFirst().joined(separator: " ").prefix(110))
    }
}

enum NoteColor: String, CaseIterable, Identifiable {
    case indigo, coral, citrus, mint, sky, lavender

    var id: String { rawValue }
}

enum Project: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case pinned = "Pinned"
    case notes = "Notes"
    case ideas = "Ideas"
    case tasks = "Tasks"
    case readLater = "Read Later"

    var id: String { rawValue }

    var canCreateNotes: Bool { self != .pinned }
}

enum NoteQuery {
    static func visible(_ notes: [Note], in project: Project) -> [Note] {
        notes
            .filter { note in
                switch project {
                case .pinned:
                    note.isPinned
                case .inbox:
                    note.project == Project.inbox.rawValue || note.project == "Daily Notes"
                case .tasks:
                    note.project == Project.tasks.rawValue || note.project == "Work"
                case .readLater:
                    note.project == Project.readLater.rawValue || note.project == "Reading"
                case .notes:
                    note.project == Project.notes.rawValue || note.project == "Personal"
                case .ideas:
                    note.project == Project.ideas.rawValue
                }
            }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
