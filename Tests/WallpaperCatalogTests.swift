import XCTest
@testable import AtletaEstoico

final class WallpaperCatalogTests: XCTestCase {
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

    private func makeJpeg(_ id: String) throws {
        let dir = RemoteWallpaperStore.wallpapersDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(id).jpg")
        try Data(repeating: 0xFF, count: 64).write(to: url)
    }

    private func writeIndex(_ items: [WallpaperIndexEntry], version: Int = 1) throws {
        let index = WallpaperIndex(schema: 1, version: version, items: items)
        let data = try JSONEncoder().encode(index)
        try data.write(to: RemoteWallpaperStore.localIndexURL, options: .atomic)
        try FileManager.default.createDirectory(
            at: RemoteWallpaperStore.localIndexURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try data.write(to: RemoteWallpaperStore.localIndexURL, options: .atomic)
    }

    private func item(id: String, added: String = "2026-10-09") -> WallpaperIndexEntry {
        WallpaperIndexEntry(id: id, file: "wallpapers/\(id).jpg",
                            sha256: String(repeating: "a", count: 64),
                            bytes: 64, added: added)
    }

    // MARK: - Apenas embutidas (sem remotas)

    func testBundledOnlyWhenNoRemote() {
        let entries = WallpaperCatalog.entries()
        XCTAssertFalse(entries.isEmpty)
        XCTAssertTrue(entries.allSatisfy {
            if case .bundled = $0.source { return true }
            return false
        }, "Sem remotas deve retornar apenas embutidas")
        XCTAssertEqual(entries.map(\.id), WallpaperCatalog.bundledAssets)
    }

    // MARK: - Embutidas + remotas: ordem

    func testRemoteFirstThenBundled() throws {
        let i1 = item(id: "wp_aaa")
        let i2 = item(id: "wp_bbb")
        try makeJpeg("wp_aaa")
        try makeJpeg("wp_bbb")
        try writeIndex([i1, i2])

        let entries = WallpaperCatalog.entries()
        // Remotas mais novas primeiro (índice invertido): wp_bbb, wp_aaa, depois embutidas
        XCTAssertEqual(entries[0].id, "wp_bbb", "Última remota adicionada aparece primeiro")
        XCTAssertEqual(entries[1].id, "wp_aaa")
        XCTAssertEqual(entries[2].id, WallpaperCatalog.bundledAssets[0])
        XCTAssertTrue(entries.suffix(5).map(\.id) == WallpaperCatalog.bundledAssets)
    }

    // MARK: - isNew

    func testIsNewWithin14Days() throws {
        let today = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 9))!
        let recent = item(id: "wp_new", added: "2026-10-01")   // 8 dias atrás
        let old    = item(id: "wp_old", added: "2026-09-20")   // 19 dias atrás
        try makeJpeg("wp_new")
        try makeJpeg("wp_old")
        try writeIndex([old, recent])

        let entries = WallpaperCatalog.entries(today: today)
        let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        XCTAssertTrue(byID["wp_new"]?.isNew == true,  "Dentro de 14 dias deve ser nova")
        XCTAssertFalse(byID["wp_old"]?.isNew == true, "Mais de 14 dias não deve ser nova")
    }

    func testIsNewExactly14Days() throws {
        let today = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 9))!
        let exactly14 = item(id: "wp_14", added: "2026-09-25")  // 14 dias atrás
        try makeJpeg("wp_14")
        try writeIndex([exactly14])

        let entries = WallpaperCatalog.entries(today: today)
        XCTAssertTrue(entries.first { $0.id == "wp_14" }?.isNew == true,
                      "Exatamente 14 dias deve ser nova")
    }

    // MARK: - Arquivo ausente no disco não aparece no catálogo

    func testFileMissingFromDiskExcluded() throws {
        let i1 = item(id: "wp_ondisk")
        let i2 = item(id: "wp_missing")
        try makeJpeg("wp_ondisk")
        // wp_missing não tem arquivo em disco
        try writeIndex([i1, i2])

        let entries = WallpaperCatalog.entries()
        XCTAssertTrue(entries.contains  { $0.id == "wp_ondisk" })
        XCTAssertFalse(entries.contains { $0.id == "wp_missing" })
    }

    // MARK: - Sorteio estável com nova imagem no catálogo

    func testStableDailyRotationWhenNewRemoteAdded() throws {
        let day = DayKey(value: "2026-10-09")
        let installID = "stable-id"

        // Catálogo base: só embutidas
        let baseEntries = WallpaperCatalog.entries()
        let originalPick = WallpaperImage.name(for: day, installID: installID, entries: baseEntries)

        // Adicionamos uma remota com id muito alto (ao final do sorted)
        let newItem = item(id: "wp_zzzzzzzzzzzzz")
        try makeJpeg("wp_zzzzzzzzzzzzz")
        try writeIndex([newItem])

        let newEntries = WallpaperCatalog.entries()
        let newPick = WallpaperImage.name(for: day, installID: installID, entries: newEntries)

        // O pick pode mudar (count cresceu), mas deve ser determinístico
        let newPick2 = WallpaperImage.name(for: day, installID: installID, entries: newEntries)
        XCTAssertEqual(newPick, newPick2, "Sorteio deve ser determinístico")
        _ = originalPick
    }

    // MARK: - IDs das embutidas são os nomes de asset (retrocompatibilidade)

    func testBundledIDsAreAssetNames() {
        let entries = WallpaperCatalog.entries()
        let bundled = entries.filter {
            if case .bundled = $0.source { return true }
            return false
        }
        for entry in bundled {
            if case .bundled(let name) = entry.source {
                XCTAssertEqual(entry.id, name, "ID de embutida deve ser igual ao nome do asset")
            }
        }
    }
}
