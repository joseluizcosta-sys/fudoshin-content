import XCTest
@testable import AtletaEstoico

final class SharedStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        SharedStore._baseURL = tempDir
    }

    override func tearDown() {
        SharedStore._baseURL = nil
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - DailyPlan

    func testSaveAndLoadDailyPlan() throws {
        let day = DayKey(value: "2026-10-03")
        let entry = DailyEntry(
            day: day,
            messageID: "msg1",
            imageID: "img1",
            trigger: .geral,
            shortText: "Curta vida.",
            inlineText: "Ânimo",
            author: "Sêneca",
            reflection: "Cada dia é completo.",
            daysToRace: 30
        )
        let plan = DailyPlan(generatedAt: Date(timeIntervalSince1970: 1_000), entries: [entry])
        try SharedStore.save(plan)

        let loaded = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(loaded.entries.count, 1)
        let loadedEntry = try XCTUnwrap(loaded.entries.first)
        XCTAssertEqual(loadedEntry.messageID, "msg1")
        XCTAssertEqual(loadedEntry.imageID, "img1")
        XCTAssertEqual(loadedEntry.day.value, "2026-10-03")
        XCTAssertEqual(loadedEntry.trigger, .geral)
        XCTAssertEqual(loadedEntry.daysToRace, 30)
    }

    func testLoadPlanWhenAbsentReturnsNil() {
        XCTAssertNil(SharedStore.loadPlan())
    }

    func testDailyPlanRoundtripPreservesAllFields() throws {
        let entries: [DailyEntry] = (0..<7).map { i in
            DailyEntry(
                day: DayKey(value: "2026-10-0\(i + 1)"),
                messageID: "m\(i)",
                imageID: "img\(i)",
                trigger: Trigger.allCases[i % Trigger.allCases.count],
                shortText: "Texto \(i)",
                inlineText: "Inline",
                author: "Autor",
                reflection: "Reflexão",
                daysToRace: i == 0 ? nil : i * 10
            )
        }
        let plan = DailyPlan(generatedAt: Date(timeIntervalSince1970: 5_000), entries: entries)
        try SharedStore.save(plan)

        let loaded = try XCTUnwrap(SharedStore.loadPlan())
        XCTAssertEqual(loaded.entries.count, 7)
        XCTAssertEqual(loaded.entries, entries)
    }

    // MARK: - SharedPreferences

    func testSaveAndLoadSharedPreferences() throws {
        let prefs = SharedPreferences(
            installID: "test-uuid",
            changeHour: 5,
            notificationHour: 8,
            categories: [.rua, .trilha],
            quoteOnWallpaper: true,
            isPremium: true
        )
        try SharedStore.save(prefs)

        let loaded = SharedStore.loadPreferences()
        XCTAssertEqual(loaded.installID, "test-uuid")
        XCTAssertEqual(loaded.changeHour, 5)
        XCTAssertEqual(loaded.notificationHour, 8)
        XCTAssertEqual(loaded.categories, [.rua, .trilha])
        XCTAssertTrue(loaded.quoteOnWallpaper)
        XCTAssertTrue(loaded.isPremium)
    }

    func testInstallIDGeneratedOnceAndPersisted() {
        let prefs1 = SharedStore.loadPreferences()
        XCTAssertFalse(prefs1.installID.isEmpty)

        let prefs2 = SharedStore.loadPreferences()
        XCTAssertEqual(prefs1.installID, prefs2.installID)
    }

    func testInstallIDIsValidUUID() {
        let prefs = SharedStore.loadPreferences()
        XCTAssertNotNil(UUID(uuidString: prefs.installID))
    }

    func testDefaultPreferencesValues() {
        let prefs = SharedStore.loadPreferences()
        XCTAssertEqual(prefs.changeHour, 0)
        XCTAssertEqual(prefs.notificationHour, 7)
        XCTAssertEqual(prefs.categories, [.trail])
        XCTAssertFalse(prefs.quoteOnWallpaper)
        XCTAssertFalse(prefs.isPremium)
    }

    // MARK: - wallpaperURL

    func testWallpaperURLContainsDayValue() {
        let day = DayKey(value: "2026-10-05")
        let url = SharedStore.wallpaperURL(for: day)
        XCTAssertEqual(url.lastPathComponent, "wallpaper_2026-10-05.png")
    }
}
