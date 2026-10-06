import AppIntents

extension LockScreenStyle: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("lock_style.param.title"))
    }

    static var caseDisplayRepresentations: [LockScreenStyle: DisplayRepresentation] = [
        .destaque:     DisplayRepresentation(title: LocalizedStringResource("lock_style.destaque")),
        .palavraChave: DisplayRepresentation(title: LocalizedStringResource("lock_style.palavrachave")),
    ]
}
