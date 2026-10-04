import XCTest
import SwiftData
@testable import AtletaEstoico

// MARK: - JournalEntry único por dia

@MainActor
final class JournalEntryTests: XCTestCase {

    var container: ModelContainer!
    var ctx: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer(
            for: JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        ctx = container.mainContext
    }

    func testJournalEntryUpsert() throws {
        let day = DayKey(Date())
        let first = JournalEntry(day: day, controlled: "Treino", notControlled: "Chuva")
        ctx.insert(first)
        try ctx.save()

        // Buscar e atualizar (simula o save do JournalEntrySheet)
        let key = day.value
        let fetched = try ctx.fetch(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.dayValue == key })
        )
        XCTAssertEqual(fetched.count, 1, "Deve haver exatamente 1 entrada por dia")
        fetched.first?.controlled = "Treino atualizado"
        try ctx.save()

        let refetched = try ctx.fetch(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.dayValue == key })
        )
        XCTAssertEqual(refetched.count, 1, "Atualização não deve criar entrada duplicada")
        XCTAssertEqual(refetched.first?.controlled, "Treino atualizado")
    }
}

// MARK: - SettingsViewModel dispara refresh

@MainActor
final class SettingsViewModelTests: XCTestCase {

    var container: ModelContainer!
    var ctx: ModelContext!

    override func setUp() async throws {
        SharedStore._baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("settings-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: SharedStore._baseURL!,
                                                withIntermediateDirectories: true)
        let prefs = SharedPreferences(installID: "test")
        try SharedStore.save(prefs)

        container = try ModelContainer(
            for: AthleteProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        ctx = container.mainContext
    }

    override func tearDown() {
        if let url = SharedStore._baseURL { try? FileManager.default.removeItem(at: url) }
        SharedStore._baseURL = nil
    }

    func testSettingsSaveTriggersRefresh() async {
        var refreshCount = 0
        let vm = SettingsViewModel(modelContext: ctx, onRefresh: { refreshCount += 1 })
        vm.prefs.notificationHour = 8
        await vm.save()
        XCTAssertEqual(refreshCount, 1, "Salvar ajustes deve disparar refresh")
    }

    func testSettingsSavePersistsPrefs() async {
        let vm = SettingsViewModel(modelContext: ctx, onRefresh: {})
        vm.prefs.notificationHour = 9
        await vm.save()
        let loaded = SharedStore.loadPreferences()
        XCTAssertEqual(loaded.notificationHour, 9, "Preferências devem ser persistidas")
    }
}

// MARK: - Progresso do Gauge

final class GaugeProgressTests: XCTestCase {

    func testGaugeProgressRaceDay() {
        let entry = DailyEntry(
            day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
            shortText: "", inlineText: "", author: "", reflection: "",
            daysToRace: 0, totalDaysToRace: 30
        )
        XCTAssertEqual(entry.gaugeProgress, 1.0, accuracy: 0.001,
                       "Dia da prova: progresso = 1.0")
    }

    func testGaugeProgressCreation() {
        let entry = DailyEntry(
            day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
            shortText: "", inlineText: "", author: "", reflection: "",
            daysToRace: 30, totalDaysToRace: 30
        )
        XCTAssertEqual(entry.gaugeProgress, 0.0, accuracy: 0.001,
                       "Dia de criação: progresso = 0.0")
    }

    func testGaugeProgressHalfway() {
        let entry = DailyEntry(
            day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
            shortText: "", inlineText: "", author: "", reflection: "",
            daysToRace: 15, totalDaysToRace: 30
        )
        XCTAssertEqual(entry.gaugeProgress, 0.5, accuracy: 0.001,
                       "Metade do caminho: progresso = 0.5")
    }

    func testGaugeProgressNoRace() {
        let entry = DailyEntry(
            day: DayKey(Date()), messageID: "", imageID: "", trigger: .geral,
            shortText: "", inlineText: "", author: "", reflection: "",
            daysToRace: nil, totalDaysToRace: nil
        )
        XCTAssertEqual(entry.gaugeProgress, 0.0, "Sem prova: progresso = 0.0")
    }
}
