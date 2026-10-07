import Foundation

enum HeroImage {
    static let fallback = "HeroSamurai"

    /// Retorna o nome do asset para o gatilho dado.
    /// Tenta `Hero_<trigger.rawValue>`; se o asset não existir (conforme `available`), retorna o fallback.
    static func name(for trigger: Trigger, available: (String) -> Bool) -> String {
        let candidate = "Hero_\(trigger.rawValue)"
        return available(candidate) ? candidate : fallback
    }
}
