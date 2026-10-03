import XCTest
import SwiftData
@testable import AtletaEstoico

@MainActor
final class OnboardingTests: XCTestCase {
    private var container: ModelContainer!
    private var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainer(
            for: Race.self, WeekPlan.self, AthleteProfile.self,
                JournalEntry.self, DeliveryLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        SharedStore._baseURL = tempDir
    }

    override func tearDown() async throws {
        SharedStore._baseURL = nil
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - commit grava Race, WeekPlan e AthleteProfile

    func testCommitCreatesRaceWeekPlanAndProfile() throws {
        let state = makeState(hasRace: true, raceName: "UTMB", category: .trail)
        let ctx = container.mainContext
        try state.commit(into: ctx)

        let races    = try ctx.fetch(FetchDescriptor<Race>())
        let weeks    = try ctx.fetch(FetchDescriptor<WeekPlan>())
        let profiles = try ctx.fetch(FetchDescriptor<AthleteProfile>())

        XCTAssertEqual(races.count, 1)
        XCTAssertEqual(races.first?.name, "UTMB")
        XCTAssertEqual(weeks.count, 1)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertTrue(profiles.first?.onboardingDone == true)
    }

    // MARK: - commit duas vezes mantém um único perfil

    func testCommitTwiceKeepsSingleProfile() throws {
        let state = makeState(hasRace: false)
        let ctx = container.mainContext

        try state.commit(into: ctx)
        try state.commit(into: ctx)

        let profiles = try ctx.fetch(FetchDescriptor<AthleteProfile>())
        let weeks    = try ctx.fetch(FetchDescriptor<WeekPlan>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(weeks.count, 1)
    }

    // MARK: - sem prova não cria Race

    func testCommitWithoutRaceDoesNotCreateRace() throws {
        let state = makeState(hasRace: false)
        try state.commit(into: container.mainContext)

        let races = try container.mainContext.fetch(FetchDescriptor<Race>())
        XCTAssertEqual(races.count, 0)
    }

    // MARK: - categoria da prova vai para SharedPreferences

    func testCommitSavesRaceCategoryToSharedPreferences() throws {
        let state = makeState(hasRace: true, raceName: "UTMB", category: .rua)
        try state.commit(into: container.mainContext)

        let prefs = SharedStore.loadPreferences()
        XCTAssertEqual(prefs.categories, [.rua])
    }

    func testCommitWithoutRaceDefaultsToTrailInSharedPreferences() throws {
        let state = makeState(hasRace: false)
        try state.commit(into: container.mainContext)

        let prefs = SharedStore.loadPreferences()
        XCTAssertEqual(prefs.categories, [.trail])
    }

    // MARK: - committed flag desabilitado após primeiro toque

    func testCommittedFlagSetAfterCommit() throws {
        let state = makeState(hasRace: false)
        XCTAssertFalse(state.committed)
        try state.commit(into: container.mainContext)
        XCTAssertTrue(state.committed)
    }

    // MARK: - normalizeWhy

    func testNormalizeWhyRemovesTrailingPunctuationAndCapitalizesFirst() {
        let s = OnboardingState()
        XCTAssertEqual(s.normalizeWhy("I love running!"), "I love running")
        XCTAssertEqual(s.normalizeWhy("running."), "Running")
        XCTAssertEqual(s.normalizeWhy("para me sentir vivo"), "Para me sentir vivo")
        XCTAssertEqual(s.normalizeWhy("  hello…  "), "Hello")
        XCTAssertEqual(s.normalizeWhy(""), "")
    }

    // MARK: - helpers

    private func makeState(
        hasRace: Bool,
        raceName: String = "",
        category: ImageCategory = .trail
    ) -> OnboardingState {
        let s = OnboardingState()
        s.hasRace = hasRace
        s.raceName = raceName
        s.raceCategory = category
        s.weekSessions = [0: .longo, 3: .forte]
        s.why = "running frees my mind"
        s.mantra = "One step at a time"
        return s
    }
}
