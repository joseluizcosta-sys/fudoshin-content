import XCTest
import CryptoKit
@testable import AtletaEstoico

// MARK: - Test helpers

private func makeSession() -> URLSession {
    let cfg = URLSessionConfiguration.ephemeral
    cfg.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: cfg)
}

private func makeStore(
    manifestURL: URL,
    suiteName: String = "test-\(UUID().uuidString)"
) -> (RemoteContentStore, UserDefaults) {
    let defaults = UserDefaults(suiteName: suiteName)!
    let store = RemoteContentStore(
        session: makeSession(),
        defaults: defaults,
        manifestURLOverride: manifestURL
    )
    return (store, defaults)
}

// Carrega base.json e arquivos de idioma do bundle real e monta um pacote remoto.
private func makePackageData(version: Int) throws -> Data {
    guard
        let baseURL  = Bundle.main.url(forResource: "base",  withExtension: "json", subdirectory: "Content/messages"),
        let enURL    = Bundle.main.url(forResource: "en",    withExtension: "json", subdirectory: "Content/messages"),
        let ptURL    = Bundle.main.url(forResource: "pt-BR", withExtension: "json", subdirectory: "Content/messages"),
        let esURL    = Bundle.main.url(forResource: "es",    withExtension: "json", subdirectory: "Content/messages")
    else { throw XCTSkip("Content files not found in test bundle — skipping") }

    var base = try JSONSerialization.jsonObject(with: Data(contentsOf: baseURL)) as! [String: Any]
    base["versao_conteudo"] = version

    let pkg: [String: Any] = [
        "schema": 3,
        "version": version,
        "generatedAt": "2026-01-01T00:00:00Z",
        "base": base,
        "locales": [
            "en":    try JSONSerialization.jsonObject(with: Data(contentsOf: enURL)),
            "pt-BR": try JSONSerialization.jsonObject(with: Data(contentsOf: ptURL)),
            "es":    try JSONSerialization.jsonObject(with: Data(contentsOf: esURL)),
        ],
    ]
    return try JSONSerialization.data(withJSONObject: pkg)
}

private func makeManifestData(
    version: Int,
    packageName: String,
    sha256: String,
    bytes: Int,
    enabled: Bool = true,
    schema: Int = 3,
    minAppBuild: Int = 1
) -> Data {
    let d: [String: Any] = [
        "schema": schema, "version": version, "url": packageName,
        "sha256": sha256, "bytes": bytes, "enabled": enabled, "minAppBuild": minAppBuild,
    ]
    return try! JSONSerialization.data(withJSONObject: d)
}

private let manifestURL = URL(string: "https://test.local/manifest.json")!
private let packageURL  = URL(string: "https://test.local/content-v999.json")!

// MARK: - Tests

@MainActor
final class RemoteContentStoreTests: XCTestCase {

    var tempDir: URL!
    var suiteName: String!

    override func setUp() async throws {
        MockURLProtocol.handlers = [:]
        MockURLProtocol.networkError = nil

        suiteName = "rcs-test-\(UUID().uuidString)"
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        SharedStore._baseURL = tempDir
        // Gravar prefs mínimas para que contentVersion do bundle funcione.
        let prefs = SharedPreferences(installID: "test")
        try SharedStore.save(prefs)
    }

    override func tearDown() async throws {
        SharedStore._baseURL = nil
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: tempDir)
    }

    // (a) versão nova válida → instala e current() usa a remota
    func testValidNewVersionInstalls() async throws {
        let pkgData = try makePackageData(version: 999)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()
        let mf  = makeManifestData(version: 999, packageName: "content-v999.json",
                                   sha256: hex, bytes: pkgData.count)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]

        let (store, _) = makeStore(manifestURL: manifestURL)
        let updated = await store.checkForUpdate(force: true)

        XCTAssertTrue(updated)
        XCTAssertNotNil(RemoteContentStore.currentContentDirectory)
        XCTAssertEqual(ContentLibrary.current().contentVersion, 999)
    }

    // (b) SHA-256 errado → rejeita e não instala
    func testWrongSHA256RejectsPackage() async throws {
        let pkgData = try makePackageData(version: 999)
        let mf = makeManifestData(version: 999, packageName: "content-v999.json",
                                  sha256: String(repeating: "0", count: 64),
                                  bytes: pkgData.count)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]

        let (store, _) = makeStore(manifestURL: manifestURL)
        let updated = await store.checkForUpdate(force: true)

        XCTAssertFalse(updated)
        XCTAssertNil(RemoteContentStore.currentContentDirectory)
    }

    // (c) conteúdo que falha no validate() → rejeita
    func testInvalidContentRejected() async throws {
        // Pacote com base.json inválido (vazio)
        let invalidBase: [String: Any] = ["schema": 3, "version": 999,
                                          "generatedAt": "2026-01-01T00:00:00Z",
                                          "base": ["versao": 3, "versao_conteudo": 999,
                                                   "idiomas_lancamento": ["en"],
                                                   "idiomas_futuros": [],
                                                   "idioma_fallback": "en",
                                                   "autores": [:], "obras": [:],
                                                   "gatilhos": [], "mensagens": [],
                                                   "limites_widget": [:]],
                                          "locales": ["en": ["idioma": "en",
                                                             "mensagens": [:],
                                                             "perguntas_diario": [],
                                                             "inline_contexto": [:]]]]
        let pkgData = try JSONSerialization.data(withJSONObject: invalidBase)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()
        let mf  = makeManifestData(version: 999, packageName: "content-v999.json",
                                   sha256: hex, bytes: pkgData.count)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]

        let (store, _) = makeStore(manifestURL: manifestURL)
        let updated = await store.checkForUpdate(force: true)

        XCTAssertFalse(updated)
    }

    // (d) enabled=false → apaga cache e current() volta ao bundle
    func testEnabledFalseClearsCache() async throws {
        // Primeiro instalar conteúdo válido
        let pkgData = try makePackageData(version: 999)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()
        var mf = makeManifestData(version: 999, packageName: "content-v999.json",
                                  sha256: hex, bytes: pkgData.count, enabled: true)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]
        let (store, defaults) = makeStore(manifestURL: manifestURL)
        _ = await store.checkForUpdate(force: true)
        XCTAssertNotNil(RemoteContentStore.currentContentDirectory)

        // Agora manifesto com enabled=false
        mf = makeManifestData(version: 1000, packageName: "content-v1000.json",
                              sha256: hex, bytes: pkgData.count, enabled: false)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200)]
        let store2 = RemoteContentStore(session: makeSession(), defaults: defaults,
                                        manifestURLOverride: manifestURL)
        _ = await store2.checkForUpdate(force: true)

        XCTAssertNil(RemoteContentStore.currentContentDirectory)
        XCTAssertLessThan(ContentLibrary.current().contentVersion, 999,
                          "Sem remote, current() deve usar bundle (versão menor que a remota)")
    }

    // (e) schema diferente ou minAppBuild maior → ignora
    func testSchemaOrBuildMismatchIgnored() async throws {
        let pkgData = try makePackageData(version: 999)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()

        // schema diferente
        var mf = makeManifestData(version: 999, packageName: "content-v999.json",
                                  sha256: hex, bytes: pkgData.count, schema: 99)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200)]
        let (store, _) = makeStore(manifestURL: manifestURL)
        let resultSchema = await store.checkForUpdate(force: true)
        XCTAssertFalse(resultSchema)

        // minAppBuild maior que build atual ("1")
        mf = makeManifestData(version: 999, packageName: "content-v999.json",
                              sha256: hex, bytes: pkgData.count, minAppBuild: 99999)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]
        let (store2, _) = makeStore(manifestURL: manifestURL)
        let resultBuild = await store2.checkForUpdate(force: true)
        XCTAssertFalse(resultBuild)
    }

    // (f) versão igual ou menor → não baixa o pacote
    func testSameVersionSkipsDownload() async throws {
        // Instalar versão 999
        let pkgData = try makePackageData(version: 999)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()
        let mf = makeManifestData(version: 999, packageName: "content-v999.json",
                                  sha256: hex, bytes: pkgData.count)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]
        let (store, defaults) = makeStore(manifestURL: manifestURL)
        _ = await store.checkForUpdate(force: true)

        // Tentar instalar mesma versão de novo
        var downloadCalled = false
        MockURLProtocol.handlers[packageURL] = .init(
            data: { downloadCalled = true; return pkgData }(),
            statusCode: 200
        )
        let store2 = RemoteContentStore(session: makeSession(), defaults: defaults,
                                        manifestURLOverride: manifestURL)
        let updated = await store2.checkForUpdate(force: true)

        XCTAssertFalse(updated, "Versão já instalada não deve reinstalar")
    }

    // (g) intervalo de 7 dias respeitado
    func testSevenDayIntervalThrottles() async throws {
        let pkgData = try makePackageData(version: 999)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()
        let mf = makeManifestData(version: 999, packageName: "content-v999.json",
                                  sha256: hex, bytes: pkgData.count)
        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    packageURL:  .init(data: pkgData, statusCode: 200)]

        let (store, defaults) = makeStore(manifestURL: manifestURL)

        // Marcar última checagem como agora
        defaults.set(Date(), forKey: "remoteContent.lastCheckDate")

        // Sem force=true, deve pular (< 7 dias)
        let updated = await store.checkForUpdate(force: false)
        XCTAssertFalse(updated, "Dentro de 7 dias não deve checar")

        // Com force=true, ignora o intervalo
        let forcedUpdated = await store.checkForUpdate(force: true)
        XCTAssertTrue(forcedUpdated)
    }

    // (h) falha de rede → nada muda, sem crash
    func testNetworkFailureIsHandled() async throws {
        MockURLProtocol.networkError = URLError(.notConnectedToInternet)

        let (store, _) = makeStore(manifestURL: manifestURL)
        let updated = await store.checkForUpdate(force: true)

        XCTAssertFalse(updated)
        XCTAssertNil(RemoteContentStore.currentContentDirectory)
    }

    // (i) falha de rede não grava lastCheck → próxima chamada tenta de novo
    func testNetworkFailureDoesNotWriteLastCheck() async throws {
        MockURLProtocol.networkError = URLError(.notConnectedToInternet)

        let (store, defaults) = makeStore(manifestURL: manifestURL)
        _ = await store.checkForUpdate(force: true)

        XCTAssertNil(defaults.object(forKey: "remoteContent.lastCheckDate"),
                     "Falha de rede não deve gravar lastCheckDate")
    }

    // (j) pasta current apagada com activeVersion=5 → reseta e baixa de novo
    func testMissingCurrentDirTriggersRedownload() async throws {
        let pkgData = try makePackageData(version: 5)
        let hex = SHA256.hash(data: pkgData).map { String(format: "%02x", $0) }.joined()
        let mf = makeManifestData(version: 5, packageName: "content-v5.json",
                                  sha256: hex, bytes: pkgData.count)
        let pkgURL = URL(string: "https://test.local/content-v5.json")!

        let (store, defaults) = makeStore(manifestURL: manifestURL)
        // Simular activeVersion=5 gravado, mas sem pasta current (apagada externamente)
        defaults.set(5, forKey: "remoteContent.activeVersion")
        XCTAssertNil(RemoteContentStore.currentContentDirectory)

        MockURLProtocol.handlers = [manifestURL: .init(data: mf, statusCode: 200),
                                    pkgURL:       .init(data: pkgData, statusCode: 200)]

        let updated = await store.checkForUpdate(force: true)

        XCTAssertTrue(updated, "Com pasta apagada, deve resetar e baixar de novo")
        XCTAssertNotNil(RemoteContentStore.currentContentDirectory)
    }
}
