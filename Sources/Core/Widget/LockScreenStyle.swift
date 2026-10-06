/// Estilos configuráveis do widget da tela de bloqueio (accessoryRectangular).
/// Mantido em Core/Widget para ser acessível nos testes via @testable import AtletaEstoico.
/// A conformance com AppEnum fica em Sources/Widget/LockScreenStyleAppEnum.swift (widget only).
enum LockScreenStyle: String, CaseIterable {
    case destaque
    case palavraChave
}
