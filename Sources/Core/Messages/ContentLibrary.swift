import Foundation

/// Carrega e valida o conteúdo de `Content/` (frases por idioma + catálogo de imagens).
/// Só usa Foundation: funciona no app e no widget (os dois incluem a pasta `Content` no bundle).
struct ContentLibrary {
    /// Idioma efetivamente carregado (ex.: "pt-BR"), já com fallback aplicado.
    let language: String
    let messages: [Message]
    let images: [ImageAsset]
    let diaryQuestions: [String]
    /// Textos de contexto do idioma: vespera_longo, vespera_forte, descanso, t30, t7, t1, d0.
    let contextTexts: [String: String]
    /// Limites de texto do widget para o idioma carregado.
    let limits: WidgetLimits

    private let source: ContentSource
    private let base: BaseContentFile
    private let catalog: ImageCatalog

    /// Chaves obrigatórias em `inline_contexto` de cada idioma.
    static let requiredContextKeys = ["vespera_longo", "vespera_forte", "descanso", "t30", "t7", "t1", "d0"]

    // MARK: - Init

    /// App e widget: lê `Content/` do bundle. `preferredLanguage` nil = idioma preferido do bundle.
    init(bundle: Bundle = .main, preferredLanguage: String? = nil) throws {
        try self.init(source: .bundle(bundle),
                      preferredLanguage: preferredLanguage ?? ContentLocale.systemPreferred(bundle: bundle))
    }

    /// Testes: lê de um diretório com a mesma estrutura de `Content/`.
    init(contentDirectory: URL, preferredLanguage: String? = nil) throws {
        try self.init(source: .directory(contentDirectory),
                      preferredLanguage: preferredLanguage ?? ContentLocale.systemPreferred())
    }

    init(source: ContentSource, preferredLanguage: String?) throws {
        let base = try Self.decode(BaseContentFile.self, name: "base", subdirectory: "messages", source: source)
        let catalog = try Self.decode(ImageCatalog.self, name: "images_seed", subdirectory: "", source: source)

        let candidates = base.launchLanguages + base.futureLanguages
        let available = candidates.filter { code in
            source.url(name: code, ext: "json", subdirectory: "messages") != nil
        }
        guard !available.isEmpty else {
            throw ContentError.noLanguageAvailable
        }
        let language = ContentLocale.resolve(preferred: preferredLanguage, available: available)
        let file = try Self.decode(LocaleContentFile.self, name: language, subdirectory: "messages", source: source)

        self.source = source
        self.base = base
        self.catalog = catalog
        self.language = language
        self.images = catalog.images
        self.diaryQuestions = file.diaryQuestions
        self.contextTexts = file.contextInline
        self.limits = Self.widgetLimits(for: language, in: base)
        self.messages = Self.buildMessages(base: base, file: file, language: language)
    }

    // MARK: - Consulta

    func message(withID id: String) -> Message? {
        messages.first { $0.id == id }
    }

    func messages(for trigger: Trigger) -> [Message] {
        messages.filter { $0.triggers.contains(trigger) }
    }

    func image(withID id: String) -> ImageAsset? {
        images.first { $0.id == id }
    }

    func images(in categories: [ImageCategory]) -> [ImageAsset] {
        images.filter { categories.contains($0.category) }
    }

    // MARK: - Validação

    /// Confere o conteúdo de TODOS os idiomas de lançamento. Lista vazia = tudo certo.
    func validate() -> [String] {
        var problems: [String] = []

        // IDs únicos
        var seenIDs = Set<String>()
        for meta in base.messages where !seenIDs.insert(meta.id).inserted {
            problems.append("base.json: ID duplicado '\(meta.id)'")
        }

        // Gatilhos
        for name in base.triggers where Trigger(rawValue: name) == nil {
            problems.append("base.json: gatilho inválido '\(name)' na lista de gatilhos")
        }
        for meta in base.messages {
            if meta.triggers.isEmpty {
                problems.append("base.json: mensagem '\(meta.id)' sem gatilhos")
            }
            for name in meta.triggers where Trigger(rawValue: name) == nil {
                problems.append("base.json: mensagem '\(meta.id)' com gatilho inválido '\(name)'")
            }
            if base.authors[meta.authorKey] == nil {
                problems.append("base.json: mensagem '\(meta.id)' com autor inexistente '\(meta.authorKey)'")
            }
            if base.works[meta.workKey] == nil {
                problems.append("base.json: mensagem '\(meta.id)' com obra inexistente '\(meta.workKey)'")
            }
        }

        // Por idioma de lançamento
        let baseIDs = Set(base.messages.map { $0.id })
        for code in base.launchLanguages {
            problems.append(contentsOf: validateLanguage(code, baseIDs: baseIDs))
        }

        problems.append(contentsOf: validateImages())
        return problems
    }

    private func validateLanguage(_ code: String, baseIDs: Set<String>) -> [String] {
        var problems: [String] = []
        let limits = Self.widgetLimits(for: code, in: base)

        // Nome de autor e de obra em cada idioma
        for (key, names) in base.authors.sorted(by: { $0.key < $1.key }) where (names[code] ?? "").isEmpty {
            problems.append("base.json: autor '\(key)' sem nome em \(code)")
        }
        for (key, names) in base.works.sorted(by: { $0.key < $1.key }) where (names[code] ?? "").isEmpty {
            problems.append("base.json: obra '\(key)' sem nome em \(code)")
        }

        let file: LocaleContentFile
        do {
            file = try Self.decode(LocaleContentFile.self, name: code, subdirectory: "messages", source: source)
        } catch {
            problems.append("\(code): \(error)")
            return problems
        }

        if file.language != code {
            problems.append("\(code).json: campo idioma é '\(file.language)'")
        }

        for meta in base.messages {
            guard let texts = file.messages[meta.id] else {
                problems.append("\(code).json: falta a mensagem '\(meta.id)'")
                continue
            }
            if texts.text.isEmpty { problems.append("\(code).json: '\(meta.id)' com texto vazio") }
            if texts.reflection.isEmpty { problems.append("\(code).json: '\(meta.id)' com reflexao vazia") }
            if texts.shortText.isEmpty { problems.append("\(code).json: '\(meta.id)' com texto_curto vazio") }
            if texts.inlineText.isEmpty { problems.append("\(code).json: '\(meta.id)' com texto_inline vazio") }
            if texts.shortText.count > limits.shortMax {
                problems.append("\(code).json: '\(meta.id)' texto_curto com \(texts.shortText.count) caracteres (máx. \(limits.shortMax))")
            }
            if texts.inlineText.count > limits.inlineMax {
                problems.append("\(code).json: '\(meta.id)' texto_inline com \(texts.inlineText.count) caracteres (máx. \(limits.inlineMax))")
            }
        }
        for id in file.messages.keys.sorted() where !baseIDs.contains(id) {
            problems.append("\(code).json: mensagem '\(id)' não existe em base.json")
        }

        for key in Self.requiredContextKeys {
            guard let value = file.contextInline[key], !value.isEmpty else {
                problems.append("\(code).json: inline_contexto sem '\(key)'")
                continue
            }
            if value.count > limits.inlineMax {
                problems.append("\(code).json: inline_contexto '\(key)' com \(value.count) caracteres (máx. \(limits.inlineMax))")
            }
        }
        if file.diaryQuestions.isEmpty {
            problems.append("\(code).json: perguntas_diario vazio")
        }
        return problems
    }

    private func validateImages() -> [String] {
        var problems: [String] = []
        var seenIDs = Set<String>()
        for image in catalog.images {
            if !seenIDs.insert(image.id).inserted {
                problems.append("images_seed.json: ID duplicado '\(image.id)'")
            }
            if (image.license ?? "").isEmpty {
                problems.append("images_seed.json: '\(image.id)' sem licenca")
            }
            if (image.tone ?? "").isEmpty {
                problems.append("images_seed.json: '\(image.id)' sem tom")
            }
            for mood in image.moods where !catalog.moods.contains(mood) {
                problems.append("images_seed.json: '\(image.id)' com humor desconhecido '\(mood)'")
            }
            if !image.isBundled && (image.pack ?? "").isEmpty {
                problems.append("images_seed.json: '\(image.id)' não embarcada e sem pacote")
            }
        }
        return problems
    }

    // MARK: - Helpers

    private static func decode<T: Decodable>(_ type: T.Type, name: String, subdirectory: String, source: ContentSource) throws -> T {
        let path = subdirectory.isEmpty ? "\(name).json" : "\(subdirectory)/\(name).json"
        guard let url = source.url(name: name, ext: "json", subdirectory: subdirectory) else {
            throw ContentError.missingFile(path)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ContentError.decoding(file: path, reason: String(describing: error))
        }
    }

    private static func widgetLimits(for language: String, in base: BaseContentFile) -> WidgetLimits {
        base.widgetLimits[language] ?? base.widgetLimits["padrao"] ?? WidgetLimits(shortMax: 70, inlineMax: 25)
    }

    private static func localizedName(_ names: LocalizedNames?, language: String, fallback: String, key: String) -> String {
        guard let names = names else { return key }
        return names[language] ?? names[fallback] ?? key
    }

    private static func buildMessages(base: BaseContentFile, file: LocaleContentFile, language: String) -> [Message] {
        base.messages.compactMap { meta -> Message? in
            // Mensagem sem texto neste idioma não aparece (validate() acusa nos idiomas de lançamento).
            guard let texts = file.messages[meta.id] else { return nil }
            return Message(
                id: meta.id,
                authorKey: meta.authorKey,
                workKey: meta.workKey,
                author: localizedName(base.authors[meta.authorKey], language: language, fallback: base.fallbackLanguage, key: meta.authorKey),
                work: localizedName(base.works[meta.workKey], language: language, fallback: base.fallbackLanguage, key: meta.workKey),
                reference: meta.reference,
                publicDomainSource: meta.publicDomainSource,
                kind: meta.kind,
                triggers: meta.triggers.compactMap { Trigger(rawValue: $0) },
                text: texts.text,
                shortText: texts.shortText,
                inlineText: texts.inlineText,
                reflection: texts.reflection
            )
        }
    }
}
