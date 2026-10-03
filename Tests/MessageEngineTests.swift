import XCTest
@testable import AtletaEstoico

final class MessageEngineTests: XCTestCase {

    // MARK: - Helpers

    private func msg(
        _ id: String,
        triggers: [Trigger] = [.geral],
        inlineText: String = ""
    ) -> Message {
        Message(
            id: id, authorKey: "seneca", workKey: "cartas_lucilio",
            author: "Seneca", work: "Letters", reference: "1.1",
            publicDomainSource: "test", kind: "citacao",
            triggers: triggers, text: "T", shortText: "S",
            inlineText: inlineText.isEmpty ? "inline-\(id)" : inlineText,
            reflection: "R"
        )
    }

    private func img(
        _ id: String,
        category: ImageCategory = .trail,
        moods: [String] = []
    ) -> ImageAsset {
        ImageAsset(
            id: id, file: "\(id).jpg", category: category, place: "Test",
            timeOfDay: "dia", season: "verao", moods: moods, tone: "escuro",
            phraseArea: "inferior", isBundled: true, pack: nil, author: "Photo",
            license: "CC0", contract: nil, visibleCredit: "Test"
        )
    }

    private func makeInput(
        trigger: Trigger = .geral,
        day: DayKey = DayKey(value: "2026-10-05"),
        installID: String = "test-id",
        isPremium: Bool = false,
        deliveredIDs: Set<String> = [],
        raceCategory: ImageCategory? = nil,
        preferredCategories: [ImageCategory] = [.trail],
        daysToRace: Int? = nil,
        tomorrowSession: SessionType? = nil
    ) -> MessageEngine.Input {
        MessageEngine.Input(
            trigger: trigger, day: day, installID: installID,
            isPremium: isPremium, recentlyDeliveredMessageIDs: deliveredIDs,
            raceCategory: raceCategory, preferredCategories: preferredCategories,
            daysToRace: daysToRace, tomorrowSession: tomorrowSession
        )
    }

    private func contentBundle() throws -> Bundle {
        let candidates = [Bundle.main] + Bundle.allBundles
        for bundle in candidates {
            if bundle.url(forResource: "base", withExtension: "json", subdirectory: "Content/messages") != nil {
                return bundle
            }
        }
        throw XCTSkip("Nenhum bundle com Content/messages/base.json")
    }

    // MARK: - 1. Estabilidade: mesma data/installID, conteúdo em ordem diferente → mesmo messageID

    func testGeralPicksSameIDRegardlessOfInsertionOrder() {
        let msgs1 = [msg("c-3"), msg("a-1"), msg("b-2")]
        let msgs2 = [msg("a-1"), msg("b-2"), msg("c-3")]
        let i = makeInput()

        let r1 = MessageEngine.pick(input: i, messages: msgs1, images: [], contextTexts: [:])
        let r2 = MessageEngine.pick(input: i, messages: msgs2, images: [], contextTexts: [:])
        XCTAssertEqual(r1.messageID, r2.messageID, "Ordem de inserção não deve afetar o resultado")
    }

    // 2. Mesmo messageID nos 3 idiomas de lançamento (usa biblioteca real do bundle)

    func testGeralPicksSameMessageAcrossLanguages() throws {
        let bundle = try contentBundle()
        let ptBR = try ContentLibrary(bundle: bundle, preferredLanguage: "pt-BR")
        let en   = try ContentLibrary(bundle: bundle, preferredLanguage: "en")
        let es   = try ContentLibrary(bundle: bundle, preferredLanguage: "es")

        let i = makeInput(day: DayKey(value: "2026-10-05"), installID: "cross-lang-test")

        let rPT = MessageEngine.pick(input: i, messages: ptBR.messages, images: ptBR.images, contextTexts: ptBR.contextTexts)
        let rEN = MessageEngine.pick(input: i, messages: en.messages,   images: en.images,   contextTexts: en.contextTexts)
        let rES = MessageEngine.pick(input: i, messages: es.messages,   images: es.images,   contextTexts: es.contextTexts)

        XCTAssertEqual(rPT.messageID, rEN.messageID, "pt-BR e en devem escolher o mesmo messageID")
        XCTAssertEqual(rPT.messageID, rES.messageID, "pt-BR e es devem escolher o mesmo messageID")
    }

    // MARK: - 3. Catálogo vazio → imageID vazio (ajuste 3)

    func testEmptyCatalogYieldsEmptyImageID() {
        let r = MessageEngine.pick(input: makeInput(), messages: [msg("a")], images: [], contextTexts: [:])
        XCTAssertEqual(r.imageID, "")
    }

    // MARK: - 4. Pool esgotado → ignorar exclusão e escolher mesmo assim (ajuste 4)

    func testExhaustedPoolFallsBackToFullPool() {
        let m1 = msg("pos-1", triggers: [.posTreino])
        let m2 = msg("pos-2", triggers: [.posTreino])
        let i  = makeInput(trigger: .posTreino, isPremium: true, deliveredIDs: ["pos-1", "pos-2"])

        let r = MessageEngine.pick(input: i, messages: [m1, m2], images: [], contextTexts: [:])
        XCTAssertTrue(r.messageID == "pos-1" || r.messageID == "pos-2",
                      "Deve escolher uma mensagem mesmo com pool esgotado")
    }

    // MARK: - 5. Usuário grátis → sempre escolhe de TODAS as mensagens (ajuste 1)

    func testFreeUserPullsFromAllMessages() {
        let mGeral   = msg("g-1", triggers: [.geral])
        let mVespera = msg("v-1", triggers: [.vesperaChave])
        let i = makeInput(trigger: .vesperaChave, isPremium: false)

        // Com 2 mensagens e DailyPicker, o resultado deve ser um dos dois IDs
        let r = MessageEngine.pick(input: i, messages: [mGeral, mVespera], images: [], contextTexts: [:])
        XCTAssertTrue(r.messageID == "g-1" || r.messageID == "v-1",
                      "Usuário grátis deve sortear de todas as mensagens")
    }

    // MARK: - 6. Usuário pago → sorteia só do pool do gatilho

    func testPaidUserPicksFromTriggerPool() {
        let mGeral = msg("g-1", triggers: [.geral])
        let mPos1  = msg("p-1", triggers: [.posTreino])
        let mPos2  = msg("p-2", triggers: [.posTreino])
        let i = makeInput(trigger: .posTreino, isPremium: true)

        let r = MessageEngine.pick(input: i, messages: [mGeral, mPos1, mPos2], images: [], contextTexts: [:])
        XCTAssertTrue(r.messageID == "p-1" || r.messageID == "p-2")
        XCTAssertNotEqual(r.messageID, "g-1")
    }

    // MARK: - 7. inlineText de contexto vem de inline_contexto do arquivo (ajuste 5)

    func testInlineText_VesperaLongo() {
        let ctx = ["vespera_longo": "Longão amanhã", "vespera_forte": "Treino forte amanhã"]
        let i   = makeInput(trigger: .vesperaChave, isPremium: true, tomorrowSession: .longo)
        let r   = MessageEngine.pick(input: i, messages: [msg("v-1", triggers: [.vesperaChave])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Longão amanhã")
    }

    func testInlineText_VesperaForte() {
        let ctx = ["vespera_longo": "Longão amanhã", "vespera_forte": "Treino forte amanhã"]
        let i   = makeInput(trigger: .vesperaChave, isPremium: true, tomorrowSession: .forte)
        let r   = MessageEngine.pick(input: i, messages: [msg("v-1", triggers: [.vesperaChave])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Treino forte amanhã")
    }

    func testInlineText_Descanso() {
        let ctx = ["descanso": "Dia de descanso"]
        let i   = makeInput(trigger: .descanso, isPremium: true)
        let r   = MessageEngine.pick(input: i, messages: [msg("d-1", triggers: [.descanso])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Dia de descanso")
    }

    func testInlineText_MarcoProva_T30() {
        let ctx = ["t30": "Faltam 30 dias", "t7": "Faltam 7 dias", "t1": "Prova amanhã", "d0": "Dia de prova"]
        let i   = makeInput(trigger: .marcoProva, isPremium: true, daysToRace: 30)
        let r   = MessageEngine.pick(input: i, messages: [msg("m-1", triggers: [.marcoProva])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Faltam 30 dias")
    }

    func testInlineText_MarcoProva_D0() {
        let ctx = ["t30": "Faltam 30 dias", "t7": "Faltam 7 dias", "t1": "Prova amanhã", "d0": "Dia de prova"]
        let i   = makeInput(trigger: .marcoProva, isPremium: true, daysToRace: 0)
        let r   = MessageEngine.pick(input: i, messages: [msg("m-1", triggers: [.marcoProva])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Dia de prova")
    }

    func testInlineText_NonContextual_UsesMessageInline() {
        let i = makeInput(trigger: .posTreino, isPremium: true)
        let r = MessageEngine.pick(input: i, messages: [msg("p-1", triggers: [.posTreino], inlineText: "Bom treino!")], images: [], contextTexts: [:])
        XCTAssertEqual(r.inlineText, "Bom treino!")
    }

    // MARK: - 8. Determinismo

    func testSameInputAlwaysGivesSameOutput() {
        let msgs = [msg("a-1"), msg("b-2"), msg("c-3")]
        let imgs = [img("img-1"), img("img-2")]
        let i    = makeInput(day: DayKey(value: "2026-10-05"), installID: "fixed")

        let r1 = MessageEngine.pick(input: i, messages: msgs, images: imgs, contextTexts: [:])
        let r2 = MessageEngine.pick(input: i, messages: msgs, images: imgs, contextTexts: [:])
        XCTAssertEqual(r1.messageID, r2.messageID)
        XCTAssertEqual(r1.imageID, r2.imageID)
    }

    // MARK: - 9. Imagem com humor preferido por gatilho

    func testDescanso_PrefersCalmaImage() {
        let imgs = [img("calma-1", moods: ["calma"]), img("epico-1", moods: ["epico"]), img("plain-1")]
        let i    = makeInput(trigger: .descanso)

        let r = MessageEngine.pick(input: i, messages: [msg("d-1")], images: imgs, contextTexts: [:])
        XCTAssertEqual(r.imageID, "calma-1")
    }

    func testRetorno_PrefersRecomeco() {
        let imgs = [img("recomeco-1", moods: ["recomeco"]), img("plain-1")]
        let i    = makeInput(trigger: .retorno)

        let r = MessageEngine.pick(input: i, messages: [msg("r-1")], images: imgs, contextTexts: [:])
        XCTAssertEqual(r.imageID, "recomeco-1")
    }

    // MARK: - 10. inline_contexto da biblioteca real (verifica chaves obrigatórias)

    func testRealLibraryHasAllRequiredContextKeys() throws {
        let bundle = try contentBundle()
        for lang in ["pt-BR", "en", "es"] {
            let lib = try ContentLibrary(bundle: bundle, preferredLanguage: lang)
            for key in ContentLibrary.requiredContextKeys {
                XCTAssertNotNil(lib.contextTexts[key], "\(lang): falta inline_contexto.\(key)")
                XCTAssertFalse(lib.contextTexts[key]!.isEmpty, "\(lang): inline_contexto.\(key) vazio")
            }
        }
    }
}
