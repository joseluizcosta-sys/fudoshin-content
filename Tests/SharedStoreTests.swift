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

    // MARK: - SharedPreferences (loadPreferences — cria arquivos)

    func testSaveAndLoadSharedPreferences() throws {
        // loadPreferences gera install_id.txt; guardamos o ID para comparar depois.
        var prefs = SharedStore.loadPreferences()
        let generatedID = prefs.installID

        // changeHour é fixo em 4; não é configurável pelo usuário
        prefs.notificationHour = 8
        prefs.categories = [.rua, .trilha]
        prefs.quoteOnWallpaper = true
        prefs.isPremium = true
        try SharedStore.save(prefs)

        let loaded = SharedStore.loadPreferences()
        XCTAssertEqual(loaded.installID, generatedID)   // install_id.txt é a fonte de verdade
        XCTAssertEqual(loaded.changeHour, 4)            // sempre 4
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

    func testInstallIDStoredInSeparateFile() throws {
        let prefs = SharedStore.loadPreferences()
        let idFile = tempDir.appendingPathComponent("install_id.txt")
        let stored = try String(contentsOf: idFile, encoding: .utf8)
        XCTAssertEqual(stored, prefs.installID)
    }

    func testInstallIDFileNeverOverwritten() throws {
        // Primeira chamada: cria install_id.txt
        let id1 = SharedStore.loadPreferences().installID
        // Segunda chamada: deve ler o mesmo arquivo, não sobrescrever
        let id2 = SharedStore.loadPreferences().installID
        XCTAssertEqual(id1, id2)
        // Verificar diretamente no arquivo
        let idFile = tempDir.appendingPathComponent("install_id.txt")
        let stored = try String(contentsOf: idFile, encoding: .utf8)
        XCTAssertEqual(stored, id1)
    }

    func testDefaultPreferencesValues() {
        let prefs = SharedStore.loadPreferences()
        XCTAssertEqual(prefs.changeHour, 4)
        XCTAssertEqual(prefs.notificationHour, 7)
        XCTAssertEqual(prefs.categories, [.trail])
        XCTAssertFalse(prefs.quoteOnWallpaper)
        XCTAssertFalse(prefs.isPremium)
    }

    // MARK: - loadPreferencesIfExists (apenas leitura — widget)

    func testLoadPreferencesIfExistsReturnsNilWhenAbsent() {
        XCTAssertNil(SharedStore.loadPreferencesIfExists())
    }

    func testLoadPreferencesIfExistsReturnsNilWithoutInstallIDFile() throws {
        // Só o JSON existe; install_id.txt não existe → nil
        let prefs = SharedPreferences.default
        try SharedStore.save(prefs)
        XCTAssertNil(SharedStore.loadPreferencesIfExists())
    }

    func testLoadPreferencesIfExistsReturnsPrefWhenBothFilesExist() {
        let prefs = SharedStore.loadPreferences()   // cria ambos os arquivos
        let loaded = SharedStore.loadPreferencesIfExists()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.installID, prefs.installID)
    }

    // MARK: - Compatibilidade com JSON antigo

    func testLegacyJSONWithMissingFieldsDecodesWithDefaults() throws {
        // Cria install_id.txt explicitamente
        try "legacy-uuid".write(
            to: tempDir.appendingPathComponent("install_id.txt"),
            atomically: true, encoding: .utf8
        )
        // JSON antigo sem 'categories' e 'quoteOnWallpaper'
        let json = #"{"installID":"ignored","changeHour":3,"notificationHour":6,"isPremium":true}"#
        try json.data(using: .utf8)!.write(
            to: tempDir.appendingPathComponent("shared_preferences.json"),
            options: .atomic
        )

        let loaded = SharedStore.loadPreferences()
        XCTAssertEqual(loaded.installID, "legacy-uuid")   // install_id.txt sobrepõe o JSON
        XCTAssertTrue(loaded.isPremium)                   // preservado
        XCTAssertEqual(loaded.changeHour, 4)              // fixo em 4, ignora valor salvo
        XCTAssertEqual(loaded.categories, [.trail])       // default (campo ausente)
        XCTAssertFalse(loaded.quoteOnWallpaper)           // default (campo ausente)
    }

    // MARK: - wallpaperImage preference

    func testDefaultWallpaperImageIsNil() {
        let prefs = SharedStore.loadPreferences()
        XCTAssertNil(prefs.wallpaperImage)
    }

    func testWallpaperImageSavedAndLoaded() throws {
        var prefs = SharedStore.loadPreferences()
        prefs.wallpaperImage = "Wallpaper_epico_3"
        try SharedStore.save(prefs)

        let loaded = SharedStore.loadPreferences()
        XCTAssertEqual(loaded.wallpaperImage, "Wallpaper_epico_3")
    }

    func testWallpaperImageNilSavedAndLoaded() throws {
        var prefs = SharedStore.loadPreferences()
        prefs.wallpaperImage = "Wallpaper_epico_1"
        try SharedStore.save(prefs)
        prefs.wallpaperImage = nil
        try SharedStore.save(prefs)

        let loaded = SharedStore.loadPreferences()
        XCTAssertNil(loaded.wallpaperImage)
    }

    func testLegacyJSONWithoutWallpaperImageDecodesNil() throws {
        try "legacy-uuid2".write(
            to: tempDir.appendingPathComponent("install_id.txt"),
            atomically: true, encoding: .utf8
        )
        let json = #"{"installID":"ignored","changeHour":4,"notificationHour":7,"categories":["trail"],"quoteOnWallpaper":false,"isPremium":false}"#
        try json.data(using: .utf8)!.write(
            to: tempDir.appendingPathComponent("shared_preferences.json"),
            options: .atomic
        )

        let loaded = SharedStore.loadPreferences()
        XCTAssertNil(loaded.wallpaperImage)
    }

    // MARK: - wallpaperURL

    func testWallpaperURLContainsDayValue() {
        let day = DayKey(value: "2026-10-05")
        let url = SharedStore.wallpaperURL(for: day)
        XCTAssertEqual(url.lastPathComponent, "wallpaper_2026-10-05.png")
    }
}
