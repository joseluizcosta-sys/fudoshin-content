import Foundation

enum ImageCategory: String, Codable, CaseIterable {
    case trail, rua, trilha
}

/// Uma imagem do catálogo `Content/images_seed.json` (chaves em português mapeadas via CodingKeys).
struct ImageAsset: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let file: String
    let category: ImageCategory
    let place: String
    let timeOfDay: String
    let season: String
    let moods: [String]
    let tone: String?
    let phraseArea: String
    let isBundled: Bool
    let pack: String?
    let author: String
    let license: String?
    let contract: String?
    let visibleCredit: String

    enum CodingKeys: String, CodingKey {
        case id
        case file = "arquivo"
        case category = "categoria"
        case place = "local"
        case timeOfDay = "horario"
        case season = "estacao"
        case moods = "humores"
        case tone = "tom"
        case phraseArea = "area_frase"
        case isBundled = "embarcada"
        case pack = "pacote"
        case author = "autor"
        case license = "licenca"
        case contract = "contrato"
        case visibleCredit = "credito_visivel"
    }
}

/// Arquivo `images_seed.json`. Campos desconhecidos (ex.: `regras_sorteio`) são ignorados.
struct ImageCatalog: Codable, Equatable {
    let version: Int?
    let categories: [String: String]
    let moods: [String]
    let images: [ImageAsset]

    enum CodingKeys: String, CodingKey {
        case version = "versao"
        case categories = "categorias"
        case moods = "humores"
        case images = "imagens"
    }
}
