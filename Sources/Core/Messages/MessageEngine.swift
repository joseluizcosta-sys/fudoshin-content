import Foundation

/// Seleciona mensagem e imagem para um dado dia, de acordo com 3.2 e 3.3 do BUILD_PLAN.
/// Não importa SwiftData: o chamador extrai os IDs entregues antes de passar para Input.
enum MessageEngine {

    struct Input {
        let trigger: Trigger
        let day: DayKey
        let installID: String
        let isPremium: Bool
        /// IDs de mensagens entregues nos últimos 30 dias (pré-filtrados pelo chamador).
        let recentlyDeliveredMessageIDs: Set<String>
        let raceCategory: ImageCategory?
        let preferredCategories: [ImageCategory]
        let daysToRace: Int?
        let tomorrowSession: SessionType?
    }

    struct Output {
        let messageID: String
        let imageID: String       // "" se nenhuma imagem disponível
        let inlineText: String
    }

    static func pick(
        input: Input,
        messages: [Message],
        images: [ImageAsset],
        contextTexts: [String: String]
    ) -> Output {
        guard !messages.isEmpty else {
            return Output(messageID: "", imageID: "", inlineText: "")
        }
        let message = pickMessage(input: input, messages: messages)
        let imageID  = pickImageID(input: input, images: images)
        let inline   = resolveInlineText(
            trigger: input.trigger,
            message: message,
            tomorrowSession: input.tomorrowSession,
            daysToRace: input.daysToRace,
            contextTexts: contextTexts
        )
        return Output(messageID: message.id, imageID: imageID, inlineText: inline)
    }

    // MARK: - Message

    private static func pickMessage(input: Input, messages: [Message]) -> Message {
        // Ordenar por id para estabilidade entre idiomas e versões (ajuste 2).
        let sorted = messages.sorted { $0.id < $1.id }

        // Usuário grátis ou gatilho geral: DailyPicker sobre TODAS as mensagens (ajuste 1).
        let effective = input.isPremium ? input.trigger : .geral
        guard effective != .geral else {
            let idx = DailyPicker.index(
                count: sorted.count, installID: input.installID, salt: "msg", day: input.day
            )
            return sorted[idx]
        }

        // Pool para o gatilho específico, ordenado por id.
        var pool = sorted.filter { $0.triggers.contains(effective) }
        if pool.isEmpty { return sorted[0] }   // sem mensagens para este gatilho: fallback

        // Excluir entregues nos últimos 30 dias; se pool esvaziar, ignorar exclusão (ajuste 4).
        let after = pool.filter { !input.recentlyDeliveredMessageIDs.contains($0.id) }
        if !after.isEmpty { pool = after }

        // SeededGenerator: seed estável por installID + dia + gatilho.
        var rng = SeededGenerator(
            seed: StableHash.fnv1a64(input.installID + input.day.value + effective.rawValue)
        )
        let idx = Int.random(in: 0..<pool.count, using: &rng)
        return pool[idx]
    }

    // MARK: - Image

    private static func pickImageID(input: Input, images: [ImageAsset]) -> String {
        guard !images.isEmpty else { return "" }   // catálogo vazio → ID vazio (ajuste 3)

        let sorted = images.sorted { $0.id < $1.id }

        // Semana da prova (≤ 7 dias): só a categoria da prova.
        let allowed: [ImageCategory]
        if let days = input.daysToRace, days <= 7, let cat = input.raceCategory {
            allowed = [cat]
        } else {
            allowed = input.preferredCategories
        }

        var pool = sorted.filter { allowed.contains($0.category) }
        if pool.isEmpty { pool = sorted }   // fallback: sem imagens nas categorias preferidas

        // Humor por gatilho.
        let moodKey: String? = switch input.trigger {
        case .descanso:     "calma"
        case .vesperaChave: "epico"
        case .retorno:      "recomeco"
        case .marcoProva:   "foco"
        default:            nil
        }
        if let mood = moodKey {
            let moodPool = pool.filter { $0.moods.contains(mood) }
            if !moodPool.isEmpty { pool = moodPool }
        }

        let idx = DailyPicker.index(
            count: pool.count, installID: input.installID, salt: "img", day: input.day
        )
        return pool[idx].id
    }

    // MARK: - Inline text

    private static func resolveInlineText(
        trigger: Trigger,
        message: Message,
        tomorrowSession: SessionType?,
        daysToRace: Int?,
        contextTexts: [String: String]
    ) -> String {
        switch trigger {
        case .vesperaChave:
            if tomorrowSession == .longo, let t = contextTexts["vespera_longo"] { return t }
            if tomorrowSession == .forte, let t = contextTexts["vespera_forte"] { return t }
        case .descanso:
            if let t = contextTexts["descanso"] { return t }
        case .marcoProva:
            let key: String? = switch daysToRace {
            case 30: "t30"
            case 7:  "t7"
            case 1:  "t1"
            case 0:  "d0"
            default: nil
            }
            if let k = key, let t = contextTexts[k] { return t }
        default:
            break
        }
        return message.inlineText
    }
}
