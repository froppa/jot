import XCTest
@testable import Jot

final class JotTests: XCTestCase {
    func testPinnedQueryFiltersAndOrdersNewestFirst() {
        let early = Note(text: "Early", project: Project.tasks.rawValue, isPinned: true, createdAt: .distantPast)
        let unpinned = Note(text: "Unpinned", project: Project.tasks.rawValue, createdAt: .now)
        let latest = Note(text: "Latest", project: Project.notes.rawValue, isPinned: true, createdAt: .distantFuture)

        let result = NoteQuery.visible([early, unpinned, latest], in: .pinned)

        XCTAssertEqual(result.map(\.text), ["Latest", "Early"])
    }

    func testNoteCanBeEditedWithoutChangingIdentity() {
        let note = Note(text: "Original", project: Project.inbox.rawValue)
        let id = note.id

        note.text = "Edited"
        note.project = Project.tasks.rawValue
        note.isPinned = true

        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.text, "Edited")
        XCTAssertEqual(note.project, Project.tasks.rawValue)
        XCTAssertTrue(note.isPinned)
    }

    func testMarkdownFormattingPreservesSource() {
        let source = "**Important** and *soon*"
        let note = Note(text: source, project: Project.inbox.rawValue)

        XCTAssertEqual(note.text, source)
        XCTAssertEqual(String(note.formattedText.characters), "Important and soon")
    }
}
