# CLAUDE.md — regras para quem for escrever o código

Você está construindo o **AtletaEstoico** (nome provisório "Ultra Mind"), app iOS nativo em Swift/SwiftUI.
Leia nesta ordem antes de qualquer tarefa: este arquivo → `docs/BUILD_PLAN.md` (a tarefa pedida) → `PROJECT_CONTEXT.md` (só se precisar de contexto de produto).

## Regras inegociáveis
1. **Execute uma tarefa por vez** (T00, T01, ...). Não adiante tarefas futuras nem "melhore" o que não foi pedido.
2. **Zero backend.** Nenhuma chamada de rede para servidor próprio ou de terceiros. Dados de saúde nunca saem do aparelho.
3. **Swift 5 language mode** (já em `project.yml`). Não ative concorrência estrita do Swift 6.
4. **iOS 17 mínimo.** Qualquer API de iOS 26 (FoundationModels) fica atrás de `#if canImport(FoundationModels)` + `if #available(iOS 26, *)`.
5. **Não invente citações.** Nunca crie frases atribuídas a Sêneca, Marco Aurélio, Epicteto ou qualquer autor. Conteúdo só vem de `Content/*.json`. A IA on-device pode escrever a *reflexão*, nunca a citação.
6. **Não use `Hasher` nem `hashValue` para nada determinístico** (é aleatório por execução). Use `StableHash` (FNV-1a) de `Core/Daily`.
7. Código de lógica (Core) **sem import de SwiftUI** e com protocolo para tudo que toca sistema (HealthKit, notificações, relógio), para poder testar com mocks.
8. Toda tarefa termina com: projeto gerado (`xcodegen generate`), **build sem erros**, **testes passando**, e um resumo do que foi feito + o que ficou pendente.
9. Se travar no mesmo erro 2 vezes, pare e descreva o erro, o que tentou e a hipótese. Não fique em loop.
10. **Nenhum texto de interface fixo no código.** Tudo no String Catalog (`Localizable.xcstrings`) com pt-BR, en e es. Conteúdo (frases) vem de `Content/messages/<idioma>.json`, nunca traduzido em tempo real.

## Comandos
```bash
xcodegen generate
xcodebuild -scheme AtletaEstoico -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme AtletaEstoico -destination 'platform=iOS Simulator,name=iPhone 16' test
```
(Ajuste o nome do simulador com `xcrun simctl list devices available`.)

## Convenções
- Um tipo por arquivo; nome do arquivo = nome do tipo.
- `@Observable` para view models (iOS 17). Nada de `ObservableObject` novo.
- Datas: sempre `Calendar.current` com o fuso do aparelho; "dia" = `startOfDay`.
- Identificador de dia: `DayKey` (string `yyyy-MM-dd`).
- UI: `Text("chave")`/`String(localized:)` com String Catalog (app e widget). Datas e distâncias com formatadores do sistema (`Date.FormatStyle`, `Measurement`).
- Idioma do conteúdo: `Bundle.main.preferredLocalizations.first`, com fallback `en` → `pt-BR`.
