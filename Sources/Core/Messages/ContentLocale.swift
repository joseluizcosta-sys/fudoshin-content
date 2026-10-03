import Foundation

/// Resolve o idioma do conteúdo (frases). Fallback: en -> pt-BR.
enum ContentLocale {
    static let fallbackChain = ["en", "pt-BR"]

    /// Idioma preferido do bundle (respeita a troca de idioma por app do iOS).
    static func systemPreferred(bundle: Bundle = .main) -> String? {
        bundle.preferredLocalizations.first
    }

    /// Escolhe, entre `available`, o idioma para `preferred`.
    /// Ex.: "pt-PT" -> "pt-BR"; "es-419" -> "es"; "de" (inexistente) -> "en".
    static func resolve(preferred: String?, available: [String]) -> String {
        if let preferred = preferred, let found = match(preferred, in: available) {
            return found
        }
        for code in fallbackChain {
            if let found = match(code, in: available) {
                return found
            }
        }
        return available.first ?? "en"
    }

    /// Procura `code` em `available`: igualdade exata (sem diferenciar caixa), depois
    /// removendo subtags do fim ("zh-Hans-CN" -> "zh-Hans"), depois mesmo código de idioma.
    static func match(_ code: String, in available: [String]) -> String? {
        let normalized = code.replacingOccurrences(of: "_", with: "-")
        if let exact = exactMatch(normalized, in: available) {
            return exact
        }
        var parts = normalized.split(separator: "-").map { String($0) }
        while parts.count > 1 {
            parts.removeLast()
            if let found = exactMatch(parts.joined(separator: "-"), in: available) {
                return found
            }
        }
        guard let language = parts.first?.lowercased() else {
            return nil
        }
        return available.first { candidate in
            candidate.split(separator: "-").first.map { String($0).lowercased() } == language
        }
    }

    private static func exactMatch(_ code: String, in available: [String]) -> String? {
        available.first { $0.caseInsensitiveCompare(code) == .orderedSame }
    }
}
