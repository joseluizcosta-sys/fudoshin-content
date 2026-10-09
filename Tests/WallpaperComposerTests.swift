import XCTest
@testable import AtletaEstoico

@MainActor
final class WallpaperComposerTests: XCTestCase {

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

    // MARK: - Helpers

    private func makeComposer(width: CGFloat = 200, height: CGFloat = 400) -> WallpaperComposer {
        WallpaperComposer(screenSize: CGSize(width: width, height: height))
    }

    private func makeEntry(day: DayKey = DayKey(Date()),
                           messageID: String = "msg1",
                           trigger: Trigger = .geral) -> DailyEntry {
        DailyEntry(
            day: day, messageID: messageID, imageID: "img1", trigger: trigger,
            shortText: "Persevera.", inlineText: "Persevera", author: "Seneca",
            reflection: "", daysToRace: nil
        )
    }

    // MARK: - Tamanho correto

    func testImageHasExactRequestedSize() async throws {
        let w: CGFloat = 300
        let h: CGFloat = 600
        let composer   = makeComposer(width: w, height: h)
        let entry      = makeEntry()

        await composer.prepareWallpaper(for: entry)

        let url  = SharedStore.wallpaperURL(for: entry.day)
        let data = try XCTUnwrap(try? Data(contentsOf: url), "PNG não foi salvo")
        let img  = try XCTUnwrap(UIImage(data: data), "Não é imagem válida")

        XCTAssertEqual(img.size.width,  w, accuracy: 1)
        XCTAssertEqual(img.size.height, h, accuracy: 1)
    }

    // MARK: - Arquivo salvo na URL correta

    func testFileSavedAtDayURL() async {
        let composer = makeComposer()
        let entry    = makeEntry()

        await composer.prepareWallpaper(for: entry)

        let url = SharedStore.wallpaperURL(for: entry.day)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path),
                      "PNG deve existir em \(url.path)")
    }

    // MARK: - Não regera se messageID e trigger iguais

    func testNoRegenIfMetaUnchanged() async throws {
        let composer = makeComposer()
        let entry    = makeEntry()

        await composer.prepareWallpaper(for: entry)

        let url  = SharedStore.wallpaperURL(for: entry.day)
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        let mod1 = attr[.modificationDate] as? Date

        // Pequena espera para garantir que a data de modificação seria diferente
        try await Task.sleep(nanoseconds: 100_000_000)
        await composer.prepareWallpaper(for: entry)

        let attr2 = try FileManager.default.attributesOfItem(atPath: url.path)
        let mod2  = attr2[.modificationDate] as? Date

        XCTAssertEqual(mod1, mod2, "Arquivo não deve ser regravado se meta não mudou")
    }

    // MARK: - Regera se messageID mudar

    func testRegenIfMessageIDChanges() async throws {
        let composer = makeComposer()
        let entry1   = makeEntry(messageID: "msgA")
        await composer.prepareWallpaper(for: entry1)

        let url  = SharedStore.wallpaperURL(for: entry1.day)
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        let mod1 = attr[.modificationDate] as? Date

        try await Task.sleep(nanoseconds: 100_000_000)
        let entry2 = makeEntry(messageID: "msgB")
        await composer.prepareWallpaper(for: entry2)

        let attr2 = try FileManager.default.attributesOfItem(atPath: url.path)
        let mod2  = attr2[.modificationDate] as? Date

        XCTAssertNotEqual(mod1, mod2, "Arquivo deve ser regravado quando messageID muda")
    }

    // MARK: - Regera se trigger mudar

    func testRegenIfTriggerChanges() async throws {
        let composer = makeComposer()
        let entry1   = makeEntry(trigger: .geral)
        await composer.prepareWallpaper(for: entry1)

        let url  = SharedStore.wallpaperURL(for: entry1.day)
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        let mod1 = attr[.modificationDate] as? Date

        try await Task.sleep(nanoseconds: 100_000_000)
        let entry2 = makeEntry(trigger: .descanso)
        await composer.prepareWallpaper(for: entry2)

        let attr2 = try FileManager.default.attributesOfItem(atPath: url.path)
        let mod2  = attr2[.modificationDate] as? Date

        XCTAssertNotEqual(mod1, mod2, "Arquivo deve ser regravado quando trigger muda")
    }

    // MARK: - Limpeza de arquivos com mais de 7 dias

    func testCleanupRemovesOldFiles() async throws {
        // Criar arquivos de PNG e meta com datas antigas
        let oldDay = DayKey(Calendar.current.date(byAdding: .day, value: -8, to: Date())!)
        let oldPNG = SharedStore.wallpaperURL(for: oldDay)
        let oldMeta = SharedStore.wallpaperMetaURL(for: oldDay)
        try "fake".write(to: oldPNG,  atomically: true, encoding: .utf8)
        try "fake".write(to: oldMeta, atomically: true, encoding: .utf8)

        let composer = makeComposer()
        let entry    = makeEntry()
        await composer.prepareWallpaper(for: entry)

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldPNG.path),
                       "PNG com 8 dias deve ser apagado")
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldMeta.path),
                       "Meta com 8 dias deve ser apagada")
    }

    // MARK: - Arquivos recentes preservados

    func testCleanupKeepsRecentFiles() async throws {
        let recentDay  = DayKey(Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
        let recentPNG  = SharedStore.wallpaperURL(for: recentDay)
        let recentMeta = SharedStore.wallpaperMetaURL(for: recentDay)
        try "fake".write(to: recentPNG,  atomically: true, encoding: .utf8)
        try "fake".write(to: recentMeta, atomically: true, encoding: .utf8)

        let composer = makeComposer()
        let entry    = makeEntry()
        await composer.prepareWallpaper(for: entry)

        XCTAssertTrue(FileManager.default.fileExists(atPath: recentPNG.path),
                      "PNG com 3 dias deve ser preservado")
    }
}

// MARK: - WallpaperIntentHelperTests

@MainActor
final class WallpaperIntentHelperTests: XCTestCase {

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

    // Intent devolve arquivo existente (sem gerar)
    func testIntentReturnsExistingFile() async throws {
        let today = DayKey(Date())
        let url   = SharedStore.wallpaperURL(for: today)
        let data  = UIImage(systemName: "photo")?.pngData() ?? Data([0x89, 0x50, 0x4E, 0x47])
        try data.write(to: url, options: .atomic)

        let returned = try await wallpaperURL()
        XCTAssertEqual(returned.lastPathComponent, url.lastPathComponent)
    }

    // Intent gera quando arquivo não existe mas há plano
    func testIntentGeneratesWhenFileMissing() async throws {
        let today = DayKey(Date())
        let entry = DailyEntry(
            day: today, messageID: "m1", imageID: "i1", trigger: .geral,
            shortText: "Age.", inlineText: "Age", author: "Autor",
            reflection: "", daysToRace: nil
        )
        let plan = DailyPlan(generatedAt: Date(), entries: [entry])
        try SharedStore.save(plan)

        let returned = try await wallpaperURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: returned.path))
    }

    // Intent lança erro quando não há plano nem arquivo
    func testIntentThrowsWhenNoContent() async {
        do {
            _ = try await wallpaperURL()
            XCTFail("Deveria lançar erro")
        } catch WallpaperIntentError.noContent {
            // esperado
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
}
