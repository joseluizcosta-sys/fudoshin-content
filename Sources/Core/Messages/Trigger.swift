import Foundation

/// Gatilhos de contexto. Os rawValues são os mesmos usados em `Content/messages/base.json`.
enum Trigger: String, Codable, CaseIterable {
    case marcoProva = "marco_prova"
    case posTreino = "pos_treino"
    case sonoRuim = "sono_ruim"
    case vesperaChave = "vespera_chave"
    case descanso
    case retorno
    case geral
}
