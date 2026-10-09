import XCTest
@testable import AtletaEstoico

/// Testa que o DailyWallpaperIntent gera entrada do dia quando o plano está vencido.
final class WallpaperIntentTests: XCTestCase {
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

    func testResolvesEntryWhenPlanIsStale() throws {
        // Plano com única entrada de 8 dias atrás
        let staleDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let staleDay  = DayKey(staleDate)
        let lib       = ContentLibrary.current()

        // Precisa de pelo menos 1 mensagem para gerar o fallback
        guard let msg = lib.messages.first else {
            throw XCTSkip("Biblioteca sem mensagens — pule no ambiente sem bundle")
        }

        let staleEntry = DailyEntry(
            day: staleDay, messageID: msg.id, imageID: "", trigger: .geral,
            shortText: msg.shortText, inlineText: msg.inlineText,
            author: msg.author, reflection: msg.reflection, daysToRace: nil
        )
        let stalePlan = DailyPlan(generatedAt: staleDate, entries: [staleEntry])
        try SharedStore.save(stalePlan)

        // Salva preferências com isPremium = true para não travar no guard de assinatura
        var prefs = SharedPreferences(installID: "test-intent")
        prefs.isPremium = true
        try SharedStore.save(prefs)

        let todayKey = DayKey(Date())
        let result = resolveEntry(for: todayKey)

        XCTAssertNotNil(result, "Deve gerar entrada mesmo com plano vencido")
        XCTAssertEqual(result?.day, todayKey, "Entrada gerada deve ser para hoje")
    }

    func testResolvesEntryWhenNoPlan() throws {
        let lib = ContentLibrary.current()
        guard lib.messages.first != nil else {
            throw XCTSkip("Biblioteca sem mensagens")
        }

        var prefs = SharedPreferences(installID: "test-intent-no-plan")
        prefs.isPremium = true
        try SharedStore.save(prefs)

        let todayKey = DayKey(Date())
        let result   = resolveEntry(for: todayKey)

        XCTAssertNotNil(result, "Deve gerar entrada mesmo sem plano salvo")
    }
}
