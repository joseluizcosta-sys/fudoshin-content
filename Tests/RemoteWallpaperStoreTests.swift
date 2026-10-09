import XCTest
import CryptoKit
@testable import AtletaEstoico

final class RemoteWallpaperStoreTests: XCTestCase {
    private var tmpDir: URL!
    private var mockSession: URLSession!
    private var defaults: UserDefaults!
    private var store: RemoteWallpaperStore!
    private let indexURL = URL(string: "https://example.com/wallpapers.json")!

    override func setUp() async throws {
        try await super.setUp()
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        SharedStore._baseURL = tmpDir

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        MockURLProtocol.handlers = [:]
        MockURLProtocol.networkError = nil
        MockURLProtocol.requestedURLs = []

        defaults = UserDefaults(suiteName: UUID().uuidString)!
        store = RemoteWallpaperStore(
            session: mockSession,
            defaults: defaults,
            indexURLOverride: indexURL
        )
    }

    override func tearDown() async throws {
        SharedStore._baseURL = nil
        try? FileManager.default.removeItem(at: tmpDir)
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeJpegData(seed: UInt8 = 0x42) -> Data {
        var d = Data(count: 512)
        d[0] = 0xFF; d[1] = 0xD8  // JPEG magic
        for i in 2..<d.count { d[i] = seed &+ UInt8(i & 0xFF) }
        return d
    }

    private func sha256hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func makeIndex(version: Int, items: [WallpaperIndexEntry]) -> Data {
        let idx = WallpaperIndex(schema: 1, version: version, items: items)
        return try! JSONEncoder().encode(idx)
    }

    private func registerImage(id: String, data: Data) {
        let url = URL(string: "https://example.com/wallpapers/\(id).jpg")!
        MockURLProtocol.handlers[url] = .init(data: data, statusCode: 200)
    }

    private func item(id: String, data: Data) -> WallpaperIndexEntry {
        WallpaperIndexEntry(id: id, file: "wallpapers/\(id).jpg",
                            sha256: sha256hex(data), bytes: data.count, added: "2026-10-09")
    }

    private var wallpapersDir: URL { RemoteWallpaperStore.wallpapersDirectory }

    private func fileExists(_ id: String) -> Bool {
        FileManager.default.fileExists(
            atPath: wallpapersDir.appendingPathComponent("\(id).jpg").path)
    }

    // MARK: - Testes

    func testDownloadsOnlyMissingItems() async throws {
        let d1 = makeJpegData(seed: 1)
        let d2 = makeJpegData(seed: 2)
        let i1 = item(id: "wp_aaa", data: d1)
        let i2 = item(id: "wp_bbb", data: d2)

        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [i1, i2]), statusCode: 200)
        registerImage(id: "wp_aaa", data: d1)
        registerImage(id: "wp_bbb", data: d2)

        await store.checkForUpdate(force: true)
        XCTAssertTrue(fileExists("wp_aaa"))
        XCTAssertTrue(fileExists("wp_bbb"))

        // Segunda chamada com versão igual — não deve baixar de novo
        MockURLProtocol.handlers["https://example.com/wallpapers/wp_aaa.jpg".asURL!] = nil
        MockURLProtocol.handlers["https://example.com/wallpapers/wp_bbb.jpg".asURL!] = nil
        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [i1, i2]), statusCode: 200)

        await store.checkForUpdate(force: true)  // versão igual → não baixa
        XCTAssertTrue(fileExists("wp_aaa"))  // arquivo ainda existe
    }

    func testShaWrongDiscardsItem() async throws {
        let d = makeJpegData(seed: 3)
        let wrongSha = "000000000000000000000000000000000000000000000000000000000000dead"
        let badItem = WallpaperIndexEntry(id: "wp_bad", file: "wallpapers/wp_bad.jpg",
                                          sha256: wrongSha, bytes: d.count, added: "2026-10-09")

        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [badItem]), statusCode: 200)
        registerImage(id: "wp_bad", data: d)

        await store.checkForUpdate(force: true)
        XCTAssertFalse(fileExists("wp_bad"), "item com SHA errado deve ser descartado")
    }

    func testRemovesItemsNotInNewIndex() async throws {
        let d1 = makeJpegData(seed: 4)
        let d2 = makeJpegData(seed: 5)
        let i1 = item(id: "wp_ccc", data: d1)
        let i2 = item(id: "wp_ddd", data: d2)

        // Primeiro download: ambos
        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [i1, i2]), statusCode: 200)
        registerImage(id: "wp_ccc", data: d1)
        registerImage(id: "wp_ddd", data: d2)
        await store.checkForUpdate(force: true)
        XCTAssertTrue(fileExists("wp_ccc"))
        XCTAssertTrue(fileExists("wp_ddd"))

        // Segunda versão: wp_ddd foi removido
        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 2, items: [i1]), statusCode: 200)
        await store.checkForUpdate(force: true)
        XCTAssertTrue(fileExists("wp_ccc"))
        XCTAssertFalse(fileExists("wp_ddd"), "item removido do índice deve ser excluído do disco")
    }

    func testPreserversChosenImageWhenRemoved() async throws {
        let d1 = makeJpegData(seed: 6)
        let d2 = makeJpegData(seed: 7)
        let i1 = item(id: "wp_eee", data: d1)
        let i2 = item(id: "wp_fff", data: d2)

        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [i1, i2]), statusCode: 200)
        registerImage(id: "wp_eee", data: d1)
        registerImage(id: "wp_fff", data: d2)
        await store.checkForUpdate(force: true)

        // Nova versão sem wp_fff, mas wp_fff é a imagem escolhida
        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 2, items: [i1]), statusCode: 200)
        await store.checkForUpdate(force: true, preferredID: "wp_fff")
        XCTAssertTrue(fileExists("wp_fff"), "imagem escolhida não deve ser removida mesmo saindo do índice")
        XCTAssertTrue(RemoteWallpaperStore.localItems().contains { $0.id == "wp_fff" },
                      "imagem escolhida deve continuar no índice local para o catálogo enxergá-la")
    }

    func testRespectsItemLimit() async throws {
        let maxItems = 40
        var items: [WallpaperIndexEntry] = []
        for i in 0..<(maxItems + 5) {
            let d = makeJpegData(seed: UInt8(i & 0xFF))
            let id = String(format: "wp_%012d", i)
            items.append(item(id: id, data: d))
            registerImage(id: id, data: d)
        }

        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: items), statusCode: 200)
        await store.checkForUpdate(force: true)

        let files = try? FileManager.default.contentsOfDirectory(at: wallpapersDir,
                                                                   includingPropertiesForKeys: nil)
        let downloaded = files?.count ?? 0
        XCTAssert(downloaded <= maxItems, "não deve exceder o limite de \(maxItems) imagens")
    }

    func testRespectsTotalBytesLimit() async throws {
        // Cria itens com bytes declarados que excedem 30 MB no total
        let tenMB = 10 * 1024 * 1024
        let hugeItem = WallpaperIndexEntry(id: "wp_huge1", file: "wallpapers/wp_huge1.jpg",
                                            sha256: "a".padding(toLength: 64, withPad: "0", startingAt: 0),
                                            bytes: tenMB, added: "2026-10-09")
        let anotherHuge = WallpaperIndexEntry(id: "wp_huge2", file: "wallpapers/wp_huge2.jpg",
                                               sha256: "b".padding(toLength: 64, withPad: "0", startingAt: 0),
                                               bytes: tenMB, added: "2026-10-09")
        let overLimit = WallpaperIndexEntry(id: "wp_huge3", file: "wallpapers/wp_huge3.jpg",
                                             sha256: "c".padding(toLength: 64, withPad: "0", startingAt: 0),
                                             bytes: 11 * 1024 * 1024, added: "2026-10-09")

        let d = makeJpegData()
        registerImage(id: "wp_huge1", data: d)
        registerImage(id: "wp_huge2", data: d)
        registerImage(id: "wp_huge3", data: d)

        MockURLProtocol.handlers[indexURL] = .init(
            data: makeIndex(version: 1, items: [hugeItem, anotherHuge, overLimit]),
            statusCode: 200)
        await store.checkForUpdate(force: true)

        // Prioriza os mais novos: huge3 (11 MB) + huge2 (10 MB) = 21 MB; huge1 estouraria 30 MB.
        // (sha falso → nada é gravado; verificamos a seleção pelas requisições, não pelo disco)
        XCTAssertFalse(MockURLProtocol.requestedURLs.contains("https://example.com/wallpapers/wp_huge1.jpg".asURL!),
                       "o item mais antigo que estoura 30 MB não deve ser baixado")
        XCTAssertTrue(MockURLProtocol.requestedURLs.contains("https://example.com/wallpapers/wp_huge3.jpg".asURL!),
                      "o item mais novo deve ser priorizado")
    }

    func testLocalIndexWrittenAfterDownload() async throws {
        let d = makeJpegData(seed: 10)
        let i1 = item(id: "wp_idx", data: d)
        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [i1]), statusCode: 200)
        registerImage(id: "wp_idx", data: d)

        await store.checkForUpdate(force: true)

        let local = RemoteWallpaperStore.localItems()
        XCTAssertEqual(local.count, 1)
        XCTAssertEqual(local[0].id, "wp_idx")
    }

    func testPartialDownloadFailureAllowsRetry() async throws {
        // Download falha por SHA errado → versão não salva → segunda chamada sem force tenta de novo
        let badData = makeJpegData(seed: 20)
        let wrongSha = String(repeating: "0", count: 63) + "f"
        let badItem = WallpaperIndexEntry(id: "wp_retry", file: "wallpapers/wp_retry.jpg",
                                          sha256: wrongSha, bytes: badData.count, added: "2026-10-09")

        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [badItem]), statusCode: 200)
        registerImage(id: "wp_retry", data: badData)

        await store.checkForUpdate(force: true)

        XCTAssertEqual(defaults.integer(forKey: "remoteWallpapers.version"), 0,
                       "versão não deve ser salva quando download falha")
        XCTAssertNil(defaults.object(forKey: "remoteWallpapers.lastCheckDate"),
                     "lastCheckDate deve ser limpo para permitir retry sem force")

        // Segunda chamada sem force: lastCheckDate está limpo, então tenta de novo
        let goodData = makeJpegData(seed: 21)
        let goodItem = WallpaperIndexEntry(id: "wp_retry", file: "wallpapers/wp_retry.jpg",
                                           sha256: sha256hex(goodData), bytes: goodData.count, added: "2026-10-09")
        MockURLProtocol.handlers[indexURL] = .init(data: makeIndex(version: 1, items: [goodItem]), statusCode: 200)
        MockURLProtocol.handlers[URL(string: "https://example.com/wallpapers/wp_retry.jpg")!] =
            .init(data: goodData, statusCode: 200)

        await store.checkForUpdate(force: false)
        XCTAssertTrue(fileExists("wp_retry"), "segunda tentativa deve baixar o item com SHA correto")
        XCTAssertEqual(defaults.integer(forKey: "remoteWallpapers.version"), 1,
                       "versão deve ser salva após download bem-sucedido")
    }

    func testSkipsCheckWithin7Days() async throws {
        defaults.set(Date(), forKey: "remoteWallpapers.lastCheckDate")
        // Sem handlers para o indexURL — se tentar buscar, vai falhar
        MockURLProtocol.networkError = URLError(.notConnectedToInternet)

        // Não deve nem tentar buscar (dentro de 7 dias, sem force)
        await store.checkForUpdate(force: false)
        // Teste passa se não crashar (sem network error sendo propagado)
    }
}

private extension String {
    var asURL: URL? { URL(string: self) }
}
