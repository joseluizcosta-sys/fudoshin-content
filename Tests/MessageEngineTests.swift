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
        deliveredIDs: Set<String> = [],
        raceCategory: ImageCategory? = nil,
        preferredCategories: [ImageCategory] = [.trail],
        daysToRace: Int? = nil,
        tomorrowSession: SessionType? = nil
    ) -> MessageEngine.Input {
        MessageEngine.Input(
            trigger: trigger, day: day, installID: installID,
            recentlyDeliveredMessageIDs: deliveredIDs,
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
        let i  = makeInput(trigger: .posTreino, deliveredIDs: ["pos-1", "pos-2"])

        let r = MessageEngine.pick(input: i, messages: [m1, m2], images: [], contextTexts: [:])
        XCTAssertTrue(r.messageID == "pos-1" || r.messageID == "pos-2",
                      "Deve escolher uma mensagem mesmo com pool esgotado")
    }

    // MARK: - 5. Gatilho específico → sorteia só do pool do gatilho

    func testSpecificTriggerPicksFromTriggerPool() {
        let mGeral = msg("g-1", triggers: [.geral])
        let mPos1  = msg("p-1", triggers: [.posTreino])
        let mPos2  = msg("p-2", triggers: [.posTreino])
        let i = makeInput(trigger: .posTreino)

        let r = MessageEngine.pick(input: i, messages: [mGeral, mPos1, mPos2], images: [], contextTexts: [:])
        XCTAssertTrue(r.messageID == "p-1" || r.messageID == "p-2",
                      "Gatilho específico deve usar apenas o pool do gatilho")
        XCTAssertNotEqual(r.messageID, "g-1")
    }

    // MARK: - 6. Gatilho .geral → sorteia de todas as mensagens

    func testGeralTriggerPicksFromAllMessages() {
        let mGeral   = msg("g-1", triggers: [.geral])
        let mVespera = msg("v-1", triggers: [.vesperaChave])
        let i = makeInput(trigger: .geral)

        let r = MessageEngine.pick(input: i, messages: [mGeral, mVespera], images: [], contextTexts: [:])
        XCTAssertTrue(r.messageID == "g-1" || r.messageID == "v-1",
                      "Gatilho .geral deve sortear de todas as mensagens")
    }

    // MARK: - 7. inlineText de contexto vem de inline_contexto do arquivo (ajuste 5)

    func testInlineText_VesperaLongo() {
        let ctx = ["vespera_longo": "Longão amanhã", "vespera_forte": "Treino forte amanhã"]
        let i   = makeInput(trigger: .vesperaChave, tomorrowSession: .longo)
        let r   = MessageEngine.pick(input: i, messages: [msg("v-1", triggers: [.vesperaChave])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Longão amanhã")
    }

    func testInlineText_VesperaForte() {
        let ctx = ["vespera_longo": "Longão amanhã", "vespera_forte": "Treino forte amanhã"]
        let i   = makeInput(trigger: .vesperaChave, tomorrowSession: .forte)
        let r   = MessageEngine.pick(input: i, messages: [msg("v-1", triggers: [.vesperaChave])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Treino forte amanhã")
    }

    func testInlineText_Descanso() {
        let ctx = ["descanso": "Dia de descanso"]
        let i   = makeInput(trigger: .descanso)
        let r   = MessageEngine.pick(input: i, messages: [msg("d-1", triggers: [.descanso])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Dia de descanso")
    }

    func testInlineText_MarcoProva_T30() {
        let ctx = ["t30": "Faltam 30 dias", "t7": "Faltam 7 dias", "t1": "Prova amanhã", "d0": "Dia de prova"]
        let i   = makeInput(trigger: .marcoProva, daysToRace: 30)
        let r   = MessageEngine.pick(input: i, messages: [msg("m-1", triggers: [.marcoProva])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Faltam 30 dias")
    }

    func testInlineText_MarcoProva_D0() {
        let ctx = ["t30": "Faltam 30 dias", "t7": "Faltam 7 dias", "t1": "Prova amanhã", "d0": "Dia de prova"]
        let i   = makeInput(trigger: .marcoProva, daysToRace: 0)
        let r   = MessageEngine.pick(input: i, messages: [msg("m-1", triggers: [.marcoProva])], images: [], contextTexts: ctx)
        XCTAssertEqual(r.inlineText, "Dia de prova")
    }

    func testInlineText_NonContextual_UsesMessageInline() {
        let i = makeInput(trigger: .posTreino)
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

    // MARK: - 11. Gatilho sem mensagens no pool → DailyPicker geral (item 2)

    func testEmptyTriggerPoolFallsBackToGeral() {
        // Nenhuma mensagem tem trigger .sonoRuim → deve sortear de todas (geral)
        let allMsgs = [msg("a-1", triggers: [.geral]), msg("b-2", triggers: [.descanso]), msg("c-3", triggers: [.marcoProva])]
        let i = makeInput(trigger: .sonoRuim)
        let r = MessageEngine.pick(input: i, messages: allMsgs, images: [], contextTexts: [:])
        XCTAssertTrue(["a-1", "b-2", "c-3"].contains(r.messageID),
                      "Pool vazio para gatilho deve usar DailyPicker geral sobre todas as mensagens")
    }

    func testEmptyTriggerPoolIsDeterministic() {
        // O fallback para geral deve ser determinístico (mesma entrada → mesmo ID)
        let allMsgs = [msg("a-1"), msg("b-2"), msg("c-3")]
        let i = makeInput(trigger: .sonoRuim, day: DayKey(value: "2026-10-05"), installID: "det-id")
        let r1 = MessageEngine.pick(input: i, messages: allMsgs, images: [], contextTexts: [:])
        let r2 = MessageEngine.pick(input: i, messages: allMsgs, images: [], contextTexts: [:])
        XCTAssertEqual(r1.messageID, r2.messageID)
    }

    // MARK: - 12. ReflectionPersonalizer async (item 3)

    func testTemplatePerssonalizerReturnsReflectionUnchanged() async {
        let p = TemplatePersonalizer()
        let result = await p.personalize(reflection: "Stay the course.", why: "freedom", trigger: .geral)
        XCTAssertEqual(result, "Stay the course.")
    }

    func testTemplatePersonalizer_DoesNotUseWhy() async {
        let p = TemplatePersonalizer()
        let r1 = await p.personalize(reflection: "Be strong.", why: "to run free", trigger: .posTreino)
        let r2 = await p.personalize(reflection: "Be strong.", why: "different why", trigger: .posTreino)
        XCTAssertEqual(r1, r2, "TemplatePersonalizer não usa o 'why'")
    }

    // MARK: - 13. Semana da prova (≤ 7 dias) → imagem sempre da categoria da prova (item 4)

    func testRaceWeek_AlwaysPicksRaceCategory() {
        // daysToRace = 5 (≤ 7), raceCategory = .rua, preferredCategories = [.trail, .trilha]
        // → pool restrito a .rua, portanto imageID deve vir de uma imagem .rua
        let msgs = [msg("any")]
        let imgs = [
            img("rua-1",    category: .rua),
            img("rua-2",    category: .rua),
            img("trail-1",  category: .trail),
            img("trilha-1", category: .trilha),
        ]

        // Testar 7 dias consecutivos para confirmar que nunca sai de .rua
        for dayOffset in 0..<7 {
            let day = DayKey(value: "2026-10-0\(5 + dayOffset)")
            let i = makeInput(
                day: day, installID: "race-week",
                raceCategory: .rua,
                preferredCategories: [.trail, .trilha],
                daysToRace: 5
            )
            let r = MessageEngine.pick(input: i, messages: msgs, images: imgs, contextTexts: [:])
            XCTAssertTrue(r.imageID == "rua-1" || r.imageID == "rua-2",
                          "Day \(day.value): esperado imagem .rua, obteve '\(r.imageID)'")
        }
    }

    func testRaceWeek_NotAppliedWhenDaysGreaterThan7() {
        // daysToRace = 8 → usa preferredCategories normalmente
        let msgs = [msg("any")]
        let imgs = [img("trail-1", category: .trail), img("rua-1", category: .rua)]
        let i = makeInput(
            raceCategory: .rua,
            preferredCategories: [.trail],
            daysToRace: 8
        )
        let r = MessageEngine.pick(input: i, messages: msgs, images: imgs, contextTexts: [:])
        XCTAssertEqual(r.imageID, "trail-1", "Com 8+ dias, deve usar preferências (trail)")
    }
}
