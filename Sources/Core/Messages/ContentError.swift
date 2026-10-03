import Foundation

enum ContentError: Error, CustomStringConvertible {
    case missingFile(String)
    case decoding(file: String, reason: String)
    case noLanguageAvailable

    var description: String {
        switch self {
        case .missingFile(let path):
            return "Arquivo de conteúdo não encontrado: \(path)"
        case .decoding(let file, let reason):
            return "Falha ao ler \(file): \(reason)"
        case .noLanguageAvailable:
            return "Nenhum arquivo de idioma encontrado em Content/messages"
        }
    }
}
