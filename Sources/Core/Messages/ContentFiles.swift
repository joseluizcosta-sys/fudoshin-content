import Foundation

// Estruturas que espelham os arquivos JSON de `Content/messages`. Uma exceção à regra
// "um tipo por arquivo": são só DTOs de leitura, sempre usados juntos.

typealias LocalizedNames = [String: String]

struct WidgetLimits: Codable, Equatable {
    let shortMax: Int
    let inlineMax: Int

    enum CodingKeys: String, CodingKey {
        case shortMax = "texto_curto_max"
        case inlineMax = "texto_inline_max"
    }
}

/// Uma mensagem em `base.json` (independente de idioma).
struct MessageMetadata: Codable, Equatable {
    let id: String
    let authorKey: String
    let workKey: String
    let reference: String
    let publicDomainSource: String
    let kind: String
    let triggers: [String]      // strings cruas; `validate()` confere se são `Trigger` válidos

    enum CodingKeys: String, CodingKey {
        case id
        case authorKey = "autor"
        case workKey = "obra"
        case reference = "ref"
        case publicDomainSource = "base_dominio_publico"
        case kind = "tipo"
        case triggers = "gatilhos"
    }
}

/// `Content/messages/base.json`
struct BaseContentFile: Codable {
    let version: Int?           // schema version (campo "versao")
    let contentVersion: Int?    // versão do conteúdo publicado (campo "versao_conteudo")
    let launchLanguages: [String]
    let futureLanguages: [String]
    let fallbackLanguage: String
    let authors: [String: LocalizedNames]
    let works: [String: LocalizedNames]
    let triggers: [String]
    let messages: [MessageMetadata]
    let widgetLimits: [String: WidgetLimits]

    enum CodingKeys: String, CodingKey {
        case version = "versao"
        case contentVersion = "versao_conteudo"
        case launchLanguages = "idiomas_lancamento"
        case futureLanguages = "idiomas_futuros"
        case fallbackLanguage = "idioma_fallback"
        case authors = "autores"
        case works = "obras"
        case triggers = "gatilhos"
        case messages = "mensagens"
        case widgetLimits = "limites_widget"
    }
}

struct MessageTexts: Codable, Equatable {
    let text: String
    let shortText: String
    let inlineText: String
    let reflection: String

    enum CodingKeys: String, CodingKey {
        case text = "texto"
        case shortText = "texto_curto"
        case inlineText = "texto_inline"
        case reflection = "reflexao"
    }
}

struct ReviewInfo: Codable, Equatable {
    let status: String
    let nativeReviewer: String?
    let date: String?

    enum CodingKeys: String, CodingKey {
        case status
        case nativeReviewer = "revisor_nativo"
        case date = "data"
    }
}

/// `Content/messages/<idioma>.json`
struct LocaleContentFile: Codable {
    let language: String
    let review: ReviewInfo?
    let messages: [String: MessageTexts]
    let diaryQuestions: [String]
    let contextInline: [String: String]

    enum CodingKeys: String, CodingKey {
        case language = "idioma"
        case review = "revisao"
        case messages = "mensagens"
        case diaryQuestions = "perguntas_diario"
        case contextInline = "inline_contexto"
    }
}
