import XCTest
@testable import ShelfNote

final class ShelfNoteTests: XCTestCase {
    func testPinnedQueryFiltersAndOrdersNewestFirst() {
        let early = Note(text: "Early", project: Project.tasks.rawValue, isPinned: true, createdAt: .distantPast)
        let unpinned = Note(text: "Unpinned", project: Project.tasks.rawValue, createdAt: .now)
        let latest = Note(text: "Latest", project: Project.notes.rawValue, isPinned: true, createdAt: .distantFuture)

        let result = NoteQuery.visible([early, unpinned, latest], in: .pinned)

        XCTAssertEqual(result.map(\.text), ["Latest", "Early"])
    }
}
