import XCTest
@testable import AtletaEstoico

final class ContentLibraryTests: XCTestCase {
    private let launchLanguages = ["pt-BR", "en", "es"]

    /// Em testes hospedados no app, `Bundle.main` é o app. Procura o bundle que contém `Content/`.
    private func contentBundle() throws -> Bundle {
        let candidates = [Bundle.main] + Bundle.allBundles
        for bundle in candidates {
            if bundle.url(forResource: "base", withExtension: "json", subdirectory: "Content/messages") != nil {
                return bundle
            }
        }
        throw XCTSkip("Nenhum bundle com Content/messages/base.json")
    }

    private func library(_ language: String?) throws -> ContentLibrary {
        try ContentLibrary(bundle: try contentBundle(), preferredLanguage: language)
    }

    // MARK: - Conteúdo real

    func testLoadsEachLaunchLanguage() throws {
        for code in launchLanguages {
            let lib = try library(code)
            XCTAssertEqual(lib.language, code)
            XCTAssertFalse(lib.messages.isEmpty, "Sem mensagens em \(code)")
            XCTAssertFalse(lib.images.isEmpty)
        }
    }

    func testValidateReportsNoProblems() throws {
        let lib = try library("en")
        XCTAssertEqual(lib.validate(), [], "Problemas de conteúdo: \(lib.validate())")
    }

    func testMessageIDsAreUnique() throws {
        let lib = try library("en")
        let ids = lib.messages.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryLaunchLanguageHasEveryID() throws {
        let reference = Set(try library("pt-BR").messages.map { $0.id })
        XCTAssertFalse(reference.isEmpty)
        for code in launchLanguages {
            let ids = Set(try library(code).messages.map { $0.id })
            XCTAssertEqual(ids, reference, "IDs diferentes em \(code)")
        }
    }

    func testTextLimitsPerLanguage() throws {
        for code in launchLanguages {
            let lib = try library(code)
            XCTAssertEqual(lib.limits, WidgetLimits(shortMax: 70, inlineMax: 25))
            for message in lib.messages {
                XCTAssertLessThanOrEqual(message.shortText.count, lib.limits.shortMax, "\(code) \(message.id) texto_curto")
                XCTAssertLessThanOrEqual(message.inlineText.count, lib.limits.inlineMax, "\(code) \(message.id) texto_inline")
            }
            for (key, value) in lib.contextTexts {
                XCTAssertLessThanOrEqual(value.count, lib.limits.inlineMax, "\(code) contexto \(key)")
            }
        }
    }

    func testEveryMessageHasValidTriggers() throws {
        let lib = try library("en")
        for message in lib.messages {
            XCTAssertFalse(message.triggers.isEmpty, "\(message.id) sem gatilho válido")
        }
        XCTAssertFalse(lib.messages(for: .geral).isEmpty)
    }

    func testAuthorAndWorkAreLocalizedInEveryLanguage() throws {
        for code in launchLanguages {
            let lib = try library(code)
            for message in lib.messages {
                XCTAssertFalse(message.author.isEmpty)
                XCTAssertFalse(message.work.isEmpty)
                XCTAssertNotEqual(message.author, message.authorKey, "Autor sem nome em \(code)")
                XCTAssertNotEqual(message.work, message.workKey, "Obra sem nome em \(code)")
            }
        }
        // Nome do autor muda conforme o idioma (dado real de base.json).
        XCTAssertEqual(try library("pt-BR").message(withID: "ma-5-16")?.author, "Marco Aurélio")
        XCTAssertEqual(try library("en").message(withID: "ma-5-16")?.author, "Marcus Aurelius")
    }

    func testContextTextsAndDiaryQuestionsExist() throws {
        for code in launchLanguages {
            let lib = try library(code)
            for key in ContentLibrary.requiredContextKeys {
                XCTAssertFalse((lib.contextTexts[key] ?? "").isEmpty, "\(code) sem contexto \(key)")
            }
            XCTAssertFalse(lib.diaryQuestions.isEmpty)
        }
    }

    func testEveryImageHasLicenseAndTone() throws {
        let lib = try library("en")
        for image in lib.images {
            XCTAssertFalse((image.license ?? "").isEmpty, "\(image.id) sem licença")
            XCTAssertFalse((image.tone ?? "").isEmpty, "\(image.id) sem tom")
        }
    }

    func testUnknownLanguageFallsBackToEnglish() throws {
        XCTAssertEqual(try library("de").language, "en")
        XCTAssertEqual(try library("fr").language, "en")
        XCTAssertEqual(try library("zh-Hans").language, "en")   // ainda sem arquivo zh-Hans
        XCTAssertEqual(try library(nil).language.isEmpty, false)
    }

    func testRegionalVariantsMapToLaunchLanguage() throws {
        XCTAssertEqual(try library("pt-PT").language, "pt-BR")
        XCTAssertEqual(try library("es-419").language, "es")
        XCTAssertEqual(try library("en-US").language, "en")
    }

    // MARK: - ContentLocale (lógica pura)

    func testContentLocaleResolve() {
        let available = ["pt-BR", "en", "es", "zh-Hans"]
        XCTAssertEqual(ContentLocale.resolve(preferred: "pt-BR", available: available), "pt-BR")
        XCTAssertEqual(ContentLocale.resolve(preferred: "pt_BR", available: available), "pt-BR")
        XCTAssertEqual(ContentLocale.resolve(preferred: "PT-br", available: available), "pt-BR")
        XCTAssertEqual(ContentLocale.resolve(preferred: "pt-PT", available: available), "pt-BR")
        XCTAssertEqual(ContentLocale.resolve(preferred: "zh-Hans-CN", available: available), "zh-Hans")
        XCTAssertEqual(ContentLocale.resolve(preferred: "de", available: available), "en")
        XCTAssertEqual(ContentLocale.resolve(preferred: nil, available: available), "en")
        XCTAssertEqual(ContentLocale.resolve(preferred: "", available: available), "en")
        // Sem "en" disponível: cai em pt-BR.
        XCTAssertEqual(ContentLocale.resolve(preferred: "de", available: ["pt-BR", "es"]), "pt-BR")
    }

    // MARK: - Diretório injetado (validate acusa problemas)

    private func writeJSON(_ object: Any, to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        try data.write(to: url)
    }

    private func makeBrokenContent() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ContentLibraryTests-\(UUID().uuidString)", isDirectory: true)
        let messages = root.appendingPathComponent("messages", isDirectory: true)
        try FileManager.default.createDirectory(at: messages, withIntermediateDirectories: true)

        let meta: [String: Any] = [
            "id": "m1", "autor": "a", "obra": "w", "ref": "1", "base_dominio_publico": "x",
            "tipo": "citacao", "gatilhos": ["geral", "bogus"]
        ]
        let base: [String: Any] = [
            "versao": 1,
            "idiomas_lancamento": ["pt-BR", "en"],
            "idiomas_futuros": [String](),
            "idioma_fallback": "en",
            "autores": ["a": ["pt-BR": "Autor", "en": "Author"]],
            "obras": ["w": ["pt-BR": "Obra"]],
            "gatilhos": ["geral", "xpto"],
            "mensagens": [meta],
            "limites_widget": ["padrao": ["texto_curto_max": 70, "texto_inline_max": 25]]
        ]
        try writeJSON(base, to: messages.appendingPathComponent("base.json"))

        let longShort = String(repeating: "x", count: 80)
        let en: [String: Any] = [
            "idioma": "en",
            "mensagens": ["m1": ["texto": "t", "texto_curto": longShort, "texto_inline": "i", "reflexao": "r"]],
            "perguntas_diario": ["q"],
            "inline_contexto": [String: String]()
        ]
        try writeJSON(en, to: messages.appendingPathComponent("en.json"))

        let pt: [String: Any] = [
            "idioma": "pt-BR",
            "mensagens": [String: Any](),
            "perguntas_diario": ["q"],
            "inline_contexto": [String: String]()
        ]
        try writeJSON(pt, to: messages.appendingPathComponent("pt-BR.json"))

        let image: [String: Any] = [
            "id": "i1", "arquivo": "trail/i1.heic", "categoria": "trail", "local": "x", "horario": "dia",
            "estacao": "verao", "humores": ["inexistente"], "tom": "", "area_frase": "centro",
            "embarcada": true, "autor": "x", "licenca": "propria", "credito_visivel": "x"
        ]
        let images: [String: Any] = [
            "versao": 1,
            "categorias": [String: String](),
            "humores": ["calma"],
            "imagens": [image]
        ]
        try writeJSON(images, to: root.appendingPathComponent("images_seed.json"))
        return root
    }

    func testValidateReportsProblemsInBrokenContent() throws {
        let root = try makeBrokenContent()
        defer { try? FileManager.default.removeItem(at: root) }

        let lib = try ContentLibrary(contentDirectory: root, preferredLanguage: "en")
        XCTAssertEqual(lib.language, "en")
        let problems = lib.validate()

        XCTAssertTrue(problems.contains { $0.contains("bogus") }, "gatilho inválido não acusado: \(problems)")
        XCTAssertTrue(problems.contains { $0.contains("xpto") }, "gatilho inválido da lista não acusado")
        XCTAssertTrue(problems.contains { $0.contains("pt-BR") && $0.contains("m1") }, "tradução ausente não acusada")
        XCTAssertTrue(problems.contains { $0.contains("texto_curto") && $0.contains("80") }, "limite não acusado")
        XCTAssertTrue(problems.contains { $0.contains("obra") && $0.contains("en") }, "nome de obra ausente não acusado")
        XCTAssertTrue(problems.contains { $0.contains("inexistente") }, "humor desconhecido não acusado")
        XCTAssertTrue(problems.contains { $0.contains("sem tom") }, "tom vazio não acusado")
        XCTAssertTrue(problems.contains { $0.contains("inline_contexto") }, "contexto ausente não acusado")
    }

    func testMissingBaseFileThrows() throws {
        let empty = FileManager.default.temporaryDirectory
            .appendingPathComponent("ContentLibraryTests-empty-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }

        XCTAssertThrowsError(try ContentLibrary(contentDirectory: empty, preferredLanguage: "en")) { error in
            guard case ContentError.missingFile = error else {
                XCTFail("Erro inesperado: \(error)")
                return
            }
        }
    }
}
