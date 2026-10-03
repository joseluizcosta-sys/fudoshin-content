import Foundation

/// Personaliza a reflexão do dia para o atleta.
protocol ReflectionPersonalizer {
    /// `reflection`: texto do JSON. `why`: porquê do atleta. Retorna a reflexão final.
    func personalize(reflection: String, why: String, trigger: Trigger) -> String
}

/// Usa a reflexão diretamente do JSON sem modificação.
struct TemplatePersonalizer: ReflectionPersonalizer {
    func personalize(reflection: String, why: String, trigger: Trigger) -> String {
        reflection
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
/// Stub T13 — por ora devolve o template; em T13 usará LanguageModelSession.
struct FoundationModelsPersonalizer: ReflectionPersonalizer {
    func personalize(reflection: String, why: String, trigger: Trigger) -> String {
        // T13: LanguageModelSession com instruções, limite 220 chars, fallback automático.
        reflection
    }
}
#endif
