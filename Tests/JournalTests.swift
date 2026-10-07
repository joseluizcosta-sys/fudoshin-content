import XCTest
import SwiftData
@testable import AtletaEstoico

final class JournalTests: XCTestCase {
    private var container: ModelContainer!
    private var ctx: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: JournalEntry.self, configurations: config)
        ctx = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        ctx = nil
    }

    func testCreateEntry() throws {
        let day = DayKey(value: "2026-10-07")
        let entry = JournalEntry(day: day, controlled: "Run 10km", notControlled: "Weather", note: "Felt great")
        ctx.insert(entry)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.controlled, "Run 10km")
        XCTAssertEqual(fetched.first?.note, "Felt great")
    }

    func testEditEntry() throws {
        let day = DayKey(value: "2026-10-07")
        let entry = JournalEntry(day: day, controlled: "Run", note: "OK")
        ctx.insert(entry)
        try ctx.save()

        entry.controlled = "Run 15km"
        entry.note = "Amazing session"
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(fetched.first?.controlled, "Run 15km")
        XCTAssertEqual(fetched.first?.note, "Amazing session")
    }

    func testDeleteEntry() throws {
        let day = DayKey(value: "2026-10-07")
        let entry = JournalEntry(day: day, controlled: "Run")
        ctx.insert(entry)
        try ctx.save()

        ctx.delete(entry)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertTrue(fetched.isEmpty)
    }

    func testNotePersists() throws {
        let day = DayKey(value: "2026-10-07")
        let entry = JournalEntry(day: day, controlled: "", notControlled: "", note: "Long note here")
        ctx.insert(entry)
        try ctx.save()

        let fetched = try XCTUnwrap(try ctx.fetch(FetchDescriptor<JournalEntry>()).first)
        XCTAssertEqual(fetched.note, "Long note here")
    }

    func testDefaultNoteIsEmpty() {
        // Entrada criada sem o campo note (equivalente a modelo antigo sem o campo)
        let entry = JournalEntry(day: DayKey(value: "2026-10-07"), controlled: "Run", notControlled: "")
        XCTAssertEqual(entry.note, "")
    }
}
