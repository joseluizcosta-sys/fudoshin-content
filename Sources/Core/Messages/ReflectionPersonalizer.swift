import Foundation

/// Personaliza a reflexão do dia para o atleta.
protocol ReflectionPersonalizer {
    /// `reflection`: texto do JSON (nunca uma citação). `why`: porquê do atleta. Retorna a reflexão final.
    func personalize(reflection: String, why: String, trigger: Trigger) async -> String
}

/// Usa a reflexão diretamente do JSON sem modificação.
struct TemplatePersonalizer: ReflectionPersonalizer {
    func personalize(reflection: String, why: String, trigger: Trigger) async -> String {
        reflection
    }
}

// MARK: - Timeout helper (testável)

private struct PersonalizationTimeout: Error {}

/// Executa `operation` com timeout. Se o timeout disparar ou a operação falhar, retorna `fallback`.
/// Injetável em testes via `timeout`.
func personalizeWithTimeout(
    timeout: TimeInterval = 3,
    fallback: String,
    operation: @escaping @Sendable () async throws -> String
) async -> String {
    await withTaskGroup(of: String?.self) { group in
        group.addTask {
            try? await operation()
        }
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            return nil  // nil = timeout disparou
        }
        for await result in group {
            group.cancelAll()
            return result ?? fallback
        }
        return fallback
    }
}

// MARK: - FoundationModels (iOS 26+)

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
struct FoundationModelsPersonalizer: ReflectionPersonalizer {
    /// Limite em segundos antes de usar o texto original como fallback.
    let timeout: TimeInterval

    init(timeout: TimeInterval = 3) {
        self.timeout = timeout
    }

    func personalize(reflection: String, why: String, trigger: Trigger) async -> String {
        guard !reflection.isEmpty else { return reflection }
        return await personalizeWithTimeout(timeout: timeout, fallback: reflection) {
            // Personalização com LanguageModelSession (T13).
            // Por ora retorna o texto original; quando o modelo estiver pronto,
            // substituir por: let session = LanguageModelSession(…); return try await session.respond(…)
            return reflection
        }
    }
}
#endif
