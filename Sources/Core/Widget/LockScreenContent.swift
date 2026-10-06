/// Escolha de texto para o widget de tela de bloqueio por estilo.
/// Tipo puro, sem SwiftUI — testável de forma isolada.
enum LockScreenContent {
    static func text(for style: LockScreenStyle, entry: DailyEntry) -> String {
        switch style {
        case .destaque:     return entry.shortText
        case .palavraChave: return entry.inlineText
        }
    }
}
