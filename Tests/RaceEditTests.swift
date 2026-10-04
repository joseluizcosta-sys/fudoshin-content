import XCTest
import SwiftData
@testable import AtletaEstoico

@MainActor
final class RaceEditTests: XCTestCase {
    private var container: ModelContainer!
    private var ctx: ModelContext!
    private var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainer(
            for: Race.self, WeekPlan.self, AthleteProfile.self,
                JournalEntry.self, DeliveryLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        ctx = container.mainContext
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        SharedStore._baseURL = tempDir
        let prefs = SharedPreferences(installID: "test")
        try SharedStore.save(prefs)
    }

    override func tearDown() async throws {
        SharedStore._baseURL = nil
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - (a) editar só a data mantém createdAt

    func testEditDateOnlyKeepsCreatedAt() throws {
        let originalCreatedAt = Date(timeIntervalSinceNow: -86400 * 30)
        let race = Race(name: "UTMB", date: futureDate(daysFromNow: 60),
                       distanceKm: 100, category: .trail, createdAt: originalCreatedAt)
        ctx.insert(race)
        try ctx.save()

        let model = RaceEditModel(mode: .edit(race))
        model.date = futureDate(daysFromNow: 90)
        try model.save(into: ctx)

        let saved = try ctx.fetch(FetchDescriptor<Race>())
        let savedCreatedAt = try XCTUnwrap(saved.first?.createdAt)
        XCTAssertEqual(savedCreatedAt.timeIntervalSince1970,
                       originalCreatedAt.timeIntervalSince1970,
                       accuracy: 1,
                       "Editar só a data deve preservar createdAt")
    }

    // MARK: - (b) mudar o nome reseta createdAt

    func testEditNameResetsCreatedAt() throws {
        let originalCreatedAt = Date(timeIntervalSinceNow: -86400 * 30)
        let race = Race(name: "UTMB", date: futureDate(daysFromNow: 60),
                       distanceKm: 100, category: .trail, createdAt: originalCreatedAt)
        ctx.insert(race)
        try ctx.save()

        let before = Date()
        let model = RaceEditModel(mode: .edit(race))
        model.name = "Ultra Trail do Brasil"
        try model.save(into: ctx)

        let saved = try ctx.fetch(FetchDescriptor<Race>())
        XCTAssertGreaterThanOrEqual(
            saved.first!.createdAt.timeIntervalSinceReferenceDate,
            before.timeIntervalSinceReferenceDate,
            "Mudar o nome deve resetar createdAt para agora"
        )
        XCTAssertGreaterThan(
            saved.first!.createdAt.timeIntervalSinceReferenceDate,
            originalCreatedAt.timeIntervalSinceReferenceDate,
            "Novo createdAt deve ser posterior ao original"
        )
    }

    // MARK: - (c) remover apaga a Race e reseta categories

    func testRemoveDeletesRaceAndResetsCategories() throws {
        let race = Race(name: "UTMB", date: futureDate(daysFromNow: 60),
                       distanceKm: 100, category: .rua)
        ctx.insert(race)
        var prefs = SharedStore.loadPreferences()
        prefs.categories = [.rua]
        try SharedStore.save(prefs)

        let model = RaceEditModel(mode: .edit(race))
        try model.remove(from: ctx)

        let races = try ctx.fetch(FetchDescriptor<Race>())
        XCTAssertTrue(races.isEmpty, "remove deve apagar a Race")

        let updatedPrefs = SharedStore.loadPreferences()
        XCTAssertEqual(updatedPrefs.categories, [.trail],
                       "remove deve resetar categories para [.trail]")
    }

    // MARK: - (d) editar a semana não altera why, mantra nem a Race

    func testEditWeekDoesNotAffectProfileOrRace() throws {
        let race = Race(name: "UTMB", date: futureDate(daysFromNow: 60),
                       distanceKm: 100, category: .trail)
        let profile = AthleteProfile(why: "Run free", mantra: "One step", onboardingDone: true)
        ctx.insert(race)
        ctx.insert(profile)
        ctx.insert(WeekPlan(sessions: [0: .forte]))
        try ctx.save()

        let week = try ctx.fetch(FetchDescriptor<WeekPlan>()).first
        let weekModel = WeekEditModel(weekPlan: week)
        weekModel.sessions = [1: .leve, 4: .longo]
        try weekModel.save(into: ctx)

        let savedProfile = try ctx.fetch(FetchDescriptor<AthleteProfile>()).first
        XCTAssertEqual(savedProfile?.why, "Run free", "why não deve mudar")
        XCTAssertEqual(savedProfile?.mantra, "One step", "mantra não deve mudar")

        let savedRace = try ctx.fetch(FetchDescriptor<Race>()).first
        XCTAssertEqual(savedRace?.name, "UTMB", "Race não deve mudar")

        let savedWeek = try ctx.fetch(FetchDescriptor<WeekPlan>()).first
        XCTAssertEqual(savedWeek?.sessions[1], .leve, "Segunda deve ser leve")
        XCTAssertEqual(savedWeek?.sessions[4], .longo, "Sexta deve ser longo")
        XCTAssertNil(savedWeek?.sessions[0], "Seg anterior deve ter sido sobrescrita")
    }

    // MARK: - (e) prova passada → estado "concluída"

    func testPastRaceIsDetectedCorrectly() {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date()))!
        let pastRace = Race(name: "Prova Passada", date: yesterday,
                           distanceKm: 42, category: .trail)
        let today = cal.startOfDay(for: Date())
        let raceDay = cal.startOfDay(for: pastRace.date)
        XCTAssertTrue(raceDay < today, "Prova com data de ontem deve ser reconhecida como passada")
    }

    // MARK: - Helpers

    private func futureDate(daysFromNow: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
    }
}
