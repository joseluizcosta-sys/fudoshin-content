import Foundation

/// Mensagem final, já no idioma resolvido: metadados (base.json) + textos (<idioma>.json)
/// + nomes de autor/obra no idioma.
struct Message: Equatable, Identifiable {
    let id: String
    let authorKey: String
    let workKey: String
    let author: String          // nome do autor no idioma
    let work: String            // nome da obra no idioma
    let reference: String       // ex.: "5.1"
    let publicDomainSource: String
    let kind: String            // "citacao"
    let triggers: [Trigger]
    let text: String
    let shortText: String       // limite por idioma (padrão 70)
    let inlineText: String      // limite por idioma (padrão 25)
    let reflection: String
}
