import XCTest
@testable import AtletaEstoico

final class WallpaperImageTests: XCTestCase {

    // MARK: - available

    func testAvailableStopsAtHole() {
        // 1, 2 existem; 3 não existe; 4 existe — deve retornar apenas [1, 2]
        let set: Set<String> = ["Wallpaper_epico_1", "Wallpaper_epico_2", "Wallpaper_epico_4"]
        let result = WallpaperImage.available { set.contains($0) }
        XCTAssertEqual(result, ["Wallpaper_epico_1", "Wallpaper_epico_2"])
    }

    func testAvailableEmpty() {
        let result = WallpaperImage.available { _ in false }
        XCTAssertTrue(result.isEmpty)
    }

    func testAvailableAll() {
        let set: Set<String> = ["Wallpaper_epico_1", "Wallpaper_epico_2", "Wallpaper_epico_3"]
        let result = WallpaperImage.available { set.contains($0) }
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first, "Wallpaper_epico_1")
        XCTAssertEqual(result.last,  "Wallpaper_epico_3")
    }

    // MARK: - name: sem imagens → nil

    func testNoImagesReturnsNil() {
        let day = DayKey(value: "2026-10-09")
        let result = WallpaperImage.name(for: day, installID: "user1") { _ in false }
        XCTAssertNil(result)
    }

    // MARK: - name: determinístico

    func testSameDaySameInstallIDSameName() {
        let day = DayKey(value: "2026-10-09")
        let set: Set<String> = ["Wallpaper_epico_1", "Wallpaper_epico_2", "Wallpaper_epico_3"]
        let exists: (String) -> Bool = { set.contains($0) }

        let r1 = WallpaperImage.name(for: day, installID: "installA", exists: exists)
        let r2 = WallpaperImage.name(for: day, installID: "installA", exists: exists)
        XCTAssertNotNil(r1)
        XCTAssertEqual(r1, r2)
    }

    func testDifferentInstallIDsMayDiffer() {
        // Com 3 imagens, installIDs diferentes podem dar imagens diferentes
        let day = DayKey(value: "2026-10-09")
        let set: Set<String> = ["Wallpaper_epico_1", "Wallpaper_epico_2", "Wallpaper_epico_3"]
        let exists: (String) -> Bool = { set.contains($0) }

        var seen: Set<String> = []
        for i in 0..<30 {
            if let name = WallpaperImage.name(for: day, installID: "user\(i)", exists: exists) {
                seen.insert(name)
            }
        }
        // Com 30 installIDs distintos e 3 imagens, espera-se mais de 1 resultado diferente
        XCTAssertGreaterThan(seen.count, 1, "Deve distribuir entre imagens com installIDs distintos")
    }

    // MARK: - name: dias consecutivos não repetem (≥ 2 imagens)

    func testConsecutiveDaysDoNotRepeat() {
        let set: Set<String> = ["Wallpaper_epico_1", "Wallpaper_epico_2", "Wallpaper_epico_3"]
        let exists: (String) -> Bool = { set.contains($0) }
        let installID = "fixed-install-id"

        // Verifica vários pares de dias consecutivos
        let startDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for offset in 0..<30 {
            let dayDate      = Calendar.current.date(byAdding: .day, value: offset,     to: startDate)!
            let nextDayDate  = Calendar.current.date(byAdding: .day, value: offset + 1, to: startDate)!

            let today    = DayKey(dayDate)
            let tomorrow = DayKey(nextDayDate)

            let nameToday    = WallpaperImage.name(for: today,    installID: installID, exists: exists)
            let nameTomorrow = WallpaperImage.name(for: tomorrow, installID: installID, exists: exists)

            XCTAssertNotNil(nameToday)
            XCTAssertNotNil(nameTomorrow)
            XCTAssertNotEqual(nameToday, nameTomorrow,
                              "Dias consecutivos não devem ter a mesma imagem (\(today.value) → \(tomorrow.value))")
        }
    }

    func testSingleImageAllowsRepeat() {
        // Com apenas 1 imagem, dias consecutivos podem (e devem) repetir
        let set: Set<String> = ["Wallpaper_epico_1"]
        let exists: (String) -> Bool = { set.contains($0) }

        let day1 = DayKey(value: "2026-10-09")
        let day2 = DayKey(value: "2026-10-10")

        let r1 = WallpaperImage.name(for: day1, installID: "u", exists: exists)
        let r2 = WallpaperImage.name(for: day2, installID: "u", exists: exists)

        XCTAssertEqual(r1, "Wallpaper_epico_1")
        XCTAssertEqual(r2, "Wallpaper_epico_1")
    }
}

// MARK: - resolve

final class WallpaperImageResolveTests: XCTestCase {

    private let set: Set<String> = ["Wallpaper_epico_1", "Wallpaper_epico_2", "Wallpaper_epico_3"]
    private var exists: (String) -> Bool { { self.set.contains($0) } }
    private let day = DayKey(value: "2026-10-09")
    private let installID = "install-abc"

    func testResolveValidPreferenceReturnsIt() {
        let result = WallpaperImage.resolve(preference: "Wallpaper_epico_2",
                                            day: day, installID: installID, exists: exists)
        XCTAssertEqual(result, "Wallpaper_epico_2")
    }

    func testResolveInvalidPreferenceFallsBackToDaily() {
        let result = WallpaperImage.resolve(preference: "Wallpaper_epico_99",
                                            day: day, installID: installID, exists: exists)
        let daily = WallpaperImage.name(for: day, installID: installID, exists: exists)
        XCTAssertEqual(result, daily)
    }

    func testResolveNilPreferenceFallsBackToDaily() {
        let result = WallpaperImage.resolve(preference: nil,
                                            day: day, installID: installID, exists: exists)
        let daily = WallpaperImage.name(for: day, installID: installID, exists: exists)
        XCTAssertEqual(result, daily)
    }
}

// MARK: - Cache regeneration test

@MainActor
final class WallpaperComposerImageNameTests: XCTestCase {

    private var tmpDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        SharedStore._baseURL = tmpDir
    }

    override func tearDown() async throws {
        SharedStore._baseURL = nil
        try? FileManager.default.removeItem(at: tmpDir)
        try await super.tearDown()
    }

    func testRegenWhenImageNameChanges() async throws {
        let entry = DailyEntry(
            day: DayKey(Date()), messageID: "m1", imageID: "i1", trigger: .geral,
            shortText: "Age.", inlineText: "Age", author: "Autor",
            reflection: "", daysToRace: nil
        )

        // Escreve meta com imageName = "Wallpaper_epico_1" manualmente
        let metaURL = SharedStore.wallpaperMetaURL(for: entry.day)
        let pngURL  = SharedStore.wallpaperURL(for: entry.day)

        let fakeMeta = WallpaperMeta(messageID: "m1", triggerRaw: "geral",
                                     imageName: "Wallpaper_epico_1",
                                     layoutVersion: WallpaperComposer.layoutVersion)
        let metaData = try JSONEncoder().encode(fakeMeta)
        try metaData.write(to: metaURL, options: .atomic)
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: pngURL, options: .atomic)  // fake PNG

        let attr1 = try FileManager.default.attributesOfItem(atPath: pngURL.path)
        let mod1  = attr1[.modificationDate] as? Date

        // Composer sem assets reais → imageName será nil → difere da meta → deve regerar
        try await Task.sleep(nanoseconds: 100_000_000)
        let composer = WallpaperComposer(screenSize: CGSize(width: 200, height: 400))
        await composer.prepareWallpaper(for: entry)

        let attr2 = try FileManager.default.attributesOfItem(atPath: pngURL.path)
        let mod2  = attr2[.modificationDate] as? Date

        XCTAssertNotEqual(mod1, mod2, "Arquivo deve ser regravado quando imageName na meta difere")
    }
}
