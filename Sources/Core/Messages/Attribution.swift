import Foundation

/// Texto de crédito da mensagem, conforme tipo (citação vs paráfrase).
/// Usada no app, widget e notificações — sem importar SwiftUI.
/// O target do widget inclui Sources/Core/Messages e Localizable.xcstrings,
/// portanto String(localized:) resolve corretamente em ambos os contextos.
func attributionText(author: String, isParaphrase: Bool) -> String {
    guard isParaphrase else { return "— \(author)" }
    // Chave com "%@" literal; nunca interpolar o autor dentro de String(localized:).
    let fmt = String(localized: "attribution.inspired")
    return String(format: fmt, author)
}
