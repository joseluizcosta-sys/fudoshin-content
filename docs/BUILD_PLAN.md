# BUILD PLAN — Fudōshin (codinome AtletaEstoico) · MVP Fase 1

> Plano de construção para ser executado tarefa por tarefa por um modelo de código (recomendado: **Claude Sonnet** no Claude Code, rodando no Mac).
> Escrito em 03/10/2026 (inclui idiomas pt-BR, en, es). Fonte de verdade do produto: `PROJECT_CONTEXT.md`. Regras de código: `CLAUDE.md`.

---

## Status
| Tarefa | Situação |
|---|---|
| T00–T02 | ✅ Concluídas (03/10/2026) — 40/40 testes passando no simulador |
| T03 | ✅ Concluída (03/10/2026) — 63/63 testes passando no simulador (revisão incluída) |
| T04 | ✅ Concluída (03/10/2026) — 66/66 testes passando no simulador (revisão incluída) |
| T05 | ✅ Concluída (03/10/2026) — 75/75 testes passando no simulador (revisão incluída) |
| T06 | ✅ Concluída (03/10/2026) — 110/110 testes passando no simulador (revisão incluída) |
| T07 | ✅ Concluída (03/10/2026) — 132/132 testes passando no simulador (revisão incluída) |
| T08 | ✅ Concluída (03/10/2026) — 143/143 testes passando no simulador (revisão incluída) |
| T09 | ✅ Concluída (03/10/2026) — 157/157 testes passando no simulador (revisão incluída) |
| T11 | ✅ Concluída (03/10/2026) — 162/162 testes passando no simulador (revisão incluída) |
| T10 | ✅ Concluída (03/10/2026) — 184/184 testes passando no simulador (revisão 2 + crédito paráfrase) |

Atualize esta tabela ao final de cada tarefa.

---

## 0. Como usar este plano

**Fluxo por tarefa:**
1. Abrir o terminal na pasta `AtletaEstoico` e rodar `claude` (modelo Sonnet).
2. Colar o prompt padrão (seção 0.2) trocando o número da tarefa.
3. Conferir os critérios de aceite da tarefa. Rodar o app no simulador quando houver tela.
4. Commit no git: `git add -A && git commit -m "T0X: <resumo>"`.
5. Nos pontos de revisão (🔍), abrir uma sessão com o modelo mais forte (Opus) só para revisar.

### 0.1 Qual modelo em cada etapa
| Etapa | Modelo | Por quê |
|---|---|---|
| T00–T15 (código) | **Sonnet** | Bom em Swift/SwiftUI, segue plano detalhado, custo bem menor que Opus |
| Revisões 🔍 (após T06, T08, T11, T15) | **Opus** | Pega erro de arquitetura e lógica que o Sonnet deixa passar |
| Erro travado (2 tentativas sem sucesso) | **Opus** | Diagnóstico mais profundo |
| Versões curtas das frases, testes repetitivos | **Haiku** | Tarefa mecânica, custo mínimo — **nunca** para criar citações |

### 0.2 Prompt padrão
```
Leia CLAUDE.md e a tarefa T0X em docs/BUILD_PLAN.md.
Execute somente a T0X. Ao final: rode xcodegen, build e testes,
e me entregue (1) arquivos criados/alterados, (2) resultado do build e testes,
(3) o que ficou pendente ou duvidoso.
```

### 0.3 Pré-requisitos (fazer uma vez)
- Mac com **Xcode 26** (necessário para compilar FoundationModels; o app continua rodando no iOS 17+).
- `brew install xcodegen`
- Conta Apple Developer (HealthKit e App Groups exigem assinatura; dados reais de saúde só no iPhone físico).
- `git init` na pasta `AtletaEstoico`.
- Claude Code instalado no Mac. **Rodar no Mac é o que permite ao modelo compilar e corrigir sozinho** (`xcodebuild`). Sem isso, você vira o "compilador humano" copiando erros.

### 0.4 Decisões fixadas para o MVP
| Tema | Decisão |
|---|---|
| iOS mínimo | **17.0**. Foundation Models com `#available(iOS 26, *)` |
| Imagens | **30 embarcadas no app** (10 por categoria). Background Assets fica para depois do beta |
| Dados app ↔ widget | Arquivo JSON no **App Group** (`group.com.atletaestoico`). Widget não usa SwiftData nem HealthKit |
| Persistência do app | **SwiftData** |
| Sorteio diário | Determinístico: permutação semeada por ID da instalação + número do dia (sem estado) |
| Linguagem | Swift 5 mode |
| Idiomas | pt-BR, en, es no lançamento. UI via String Catalog; frases via `Content/messages/<idioma>.json`. Sem tradução em tempo real |

---

## 1. Arquitetura alvo

```
Sources/
├── App/
│   ├── AtletaEstoicoApp.swift        # @main, ModelContainer, injeção de dependências
│   ├── AppEnvironment.swift          # container de serviços (reais ou mocks)
│   └── RootView.swift                # Onboarding se não configurado; senão TabView
├── Core/
│   ├── Daily/                        # compartilhado com o widget
│   │   ├── DayKey.swift
│   │   ├── StableHash.swift          # FNV-1a 64 bits
│   │   ├── SeededGenerator.swift     # SplitMix64: RandomNumberGenerator
│   │   ├── DailyPicker.swift         # permutação determinística por ciclo
│   │   ├── DailyPlan.swift           # Codable: o que cada dia mostra
│   │   └── SharedStore.swift         # lê/grava DailyPlan + preferências no App Group
│   ├── Messages/                     # compartilhado com o widget
│   │   ├── Message.swift             # metadados (base.json) + textos localizados (<idioma>.json)
│   │   ├── ContentLocale.swift       # resolve idioma do conteúdo com fallback en → pt-BR
│   │   ├── ImageAsset.swift          # Codable do images_seed.json
│   │   ├── ContentLibrary.swift      # carrega e valida os JSON do bundle
│   │   ├── Trigger.swift             # enum dos gatilhos
│   │   ├── MessageEngine.swift
│   │   └── ReflectionPersonalizer.swift  # protocolo + implementação FoundationModels + fallback
│   ├── Context/
│   │   ├── TrainingContext.swift     # struct com tudo que o TriggerEngine precisa
│   │   ├── TriggerEngine.swift       # função pura: contexto -> Trigger
│   │   └── ContextBuilder.swift      # monta TrainingContext a partir de dados + HealthKit
│   ├── Health/
│   │   ├── HealthDataProviding.swift # protocolo
│   │   ├── HealthKitService.swift    # implementação real
│   │   └── SleepCalculator.swift     # soma de sono com união de intervalos
│   ├── Planning/
│   │   └── DailyPlanner.swift        # orquestra: contexto -> plano 7 dias -> SharedStore, widget, notificações
│   ├── Notifications/
│   │   └── NotificationScheduler.swift
│   └── Wallpaper/
│       ├── WallpaperComposer.swift   # foto + frase -> UIImage na resolução da tela
│       └── DailyWallpaperIntent.swift  # App Intent + AppShortcutsProvider
├── Data/                             # SwiftData
│   ├── Race.swift
│   ├── WeekPlan.swift
│   ├── AthleteProfile.swift
│   ├── JournalEntry.swift
│   └── DeliveryLog.swift
├── Features/
│   ├── Onboarding/  (OnboardingFlow, RaceStep, WeekStep, WhyStep, PermissionsStep)
│   ├── Today/       (TodayView, TodayViewModel)
│   ├── Race/        (RaceView)
│   ├── Mantra/      (MantraView)
│   ├── Journal/     (JournalView, JournalEntrySheet)
│   ├── Settings/    (SettingsView, WallpaperSetupGuide)
│   └── Paywall/     (PaywallView, EntitlementStore)
├── Shared/
│   └── Theme.swift
└── Widget/
    ├── AtletaEstoicoWidgetBundle.swift
    ├── DailyProvider.swift           # TimelineProvider
    ├── LockScreenViews.swift         # rectangular, inline, circular
    └── HomeScreenViews.swift         # medium, large (com paisagem)
Tests/
    ├── StableHashTests.swift, DailyPickerTests.swift, ContentLibraryTests.swift,
    ├── TriggerEngineTests.swift, SleepCalculatorTests.swift, MessageEngineTests.swift,
    └── DailyPlannerTests.swift
```

**Regra de dependência:** `Features` → `Core` + `Data`. `Core` não importa `Features`. `Widget` só usa `Core/Daily` e `Core/Messages`.

---

## 2. Contratos principais (assinaturas a respeitar)

```swift
// Core/Daily
struct DayKey: Hashable, Codable, Comparable { let value: String   // "yyyy-MM-dd"
    init(_ date: Date, calendar: Calendar = .current)
    var dayNumber: Int { get }            // dias desde 2026-01-01, para indexar permutações
}
enum StableHash { static func fnv1a64(_ s: String) -> UInt64 }
struct SeededGenerator: RandomNumberGenerator { init(seed: UInt64); mutating func next() -> UInt64 } // SplitMix64

enum DailyPicker {
    /// Índice do item do dia: permutação de 0..<count embaralhada com semente (installID + ciclo).
    /// Garante zero repetição dentro de um ciclo de `count` dias.
    static func index(count: Int, installID: String, salt: String, day: DayKey) -> Int
}

struct DailyEntry: Codable, Equatable {
    let day: DayKey
    let messageID: String
    let imageID: String
    let trigger: Trigger
    let shortText: String        // ≤ 70
    let inlineText: String       // ≤ 25 (ou texto de contexto, ex.: "Longão amanhã")
    let author: String
    let reflection: String
    let daysToRace: Int?
}
struct DailyPlan: Codable { let generatedAt: Date; let entries: [DailyEntry] }  // hoje + 6 dias

struct SharedPreferences: Codable {
    var installID: String
    var changeHour: Int              // 0...23, padrão 0
    var notificationHour: Int        // padrão 7
    var categories: [ImageCategory]  // trail, rua, trilha
    var quoteOnWallpaper: Bool       // padrão false quando widget de bloqueio ativo
    var isPremium: Bool
}
enum SharedStore {
    static let groupID = "group.com.atletaestoico"
    static func loadPlan() -> DailyPlan?;   static func save(_ plan: DailyPlan) throws
    static func loadPreferences() -> SharedPreferences; static func save(_ p: SharedPreferences) throws
    static func wallpaperURL(for day: DayKey) -> URL
}

// Core/Messages
enum Trigger: String, Codable, CaseIterable {
    case marcoProva = "marco_prova", posTreino = "pos_treino", sonoRuim = "sono_ruim",
         vesperaChave = "vespera_chave", descanso, retorno, geral
}
enum ImageCategory: String, Codable, CaseIterable { case trail, rua, trilha }

// Core/Context
struct TrainingContext {
    let today: Date
    let raceDate: Date?
    let raceCategory: ImageCategory?
    let tomorrowSession: SessionType?   // .longo, .forte, .descanso, .leve
    let todaySession: SessionType?
    let lastWorkoutEnd: Date?
    let lastPostWorkoutDelivered: Date?
    let lastNightSleepHours: Double?
    let sleepGoalHours: Double          // padrão 7
    let daysSinceLastWorkout: Int?
}
enum TriggerEngine { static func trigger(for c: TrainingContext, now: Date) -> Trigger }

// Core/Health
protocol HealthDataProviding {
    func requestAuthorization() async throws
    func recentWorkouts(days: Int) async throws -> [WorkoutSummary]   // start, end, km, tipo
    func lastNightSleepHours(reference: Date) async throws -> Double?
    func startObserving(onChange: @escaping () -> Void)
}
```

---

## 3. Regras de negócio (o modelo deve implementar exatamente isto)

### 3.1 Prioridade dos gatilhos (TriggerEngine)
Avaliar em ordem; o primeiro que bater vence.
1. **marco_prova** — `raceDate` existe e faltam exatamente 30, 7, 1 ou 0 dias.
2. **pos_treino** — `lastWorkoutEnd` nas últimas 3h **e** ainda não houve pos_treino entregue para esse treino.
3. **sono_ruim** — `lastNightSleepHours` existe e é `< sleepGoalHours - 1` (padrão: < 6h) **e** agora é antes das 12h.
4. **vespera_chave** — amanhã é `.longo` ou `.forte`.
5. **descanso** — hoje é `.descanso`.
6. **retorno** — `daysSinceLastWorkout >= 7` (constante `TriggerEngine.returnThresholdDays`).
   Com `lastExternalDataDate` ≤ 48h: pausa real → `.retorno`. Com `lastExternalDataDate` > 48h: sincronização suspeita (`syncSuspect`) → **não** `.retorno`, cai para geral. Sem `lastExternalDataDate` (sem relógio nos últimos 30 dias): `.retorno`.
7. **geral** — caso contrário.

Gatilhos **planejáveis** (entram no plano de 7 dias): marco_prova, vespera_chave, descanso, geral.
Gatilhos **de evento** (substituem a entrada de hoje quando ocorrem): pos_treino, sono_ruim, retorno.

### 3.2 Escolha da mensagem (MessageEngine)
- **geral:** `DailyPicker.index(count: geral.count, installID, salt: "msg", day)` sobre as mensagens com gatilho `geral` (ou todas, se usuário grátis). Sem estado, sem repetição no ciclo.
- **demais gatilhos:** filtrar mensagens com esse gatilho, excluir as entregues nos últimos 30 dias (`DeliveryLog`), sortear com `SeededGenerator(seed: fnv1a64(installID + day + trigger))`. Se o filtro esvaziar, ignorar a exclusão.
- **Grátis:** sempre `geral` (sem contexto). **Pago:** gatilho do TriggerEngine.
- **inlineText:** em gatilho planejável de contexto use texto fixo ("Longão amanhã", "Dia de descanso", "Faltam 7 dias", "Dia de prova"); senão `texto_inline` da mensagem.

### 3.3 Escolha da imagem
- Categorias permitidas = preferências do usuário (grátis: só a categoria da prova, ou `trail` se não houver prova).
- Semana da prova (≤ 7 dias): só a categoria da prova.
- Humor preferido por gatilho: descanso → `calma`, vespera_chave → `epico`, retorno → `recomeco`, marco_prova → `foco`. Se houver imagens com o humor, sortear entre elas; senão, todas.
- Sem gatilho de humor: `DailyPicker.index` sobre as imagens permitidas, `salt: "img"`.

### 3.4 Sono (SleepCalculator)
- Considerar amostras `HKCategoryType(.sleepAnalysis)` entre 18h de ontem e 12h de hoje.
- Contar só `asleepUnspecified`, `asleepCore`, `asleepDeep`, `asleepREM` (ignorar `inBed` e `awake`).
- **Unir intervalos sobrepostos** antes de somar (Garmin e Apple Watch podem gravar o mesmo sono).
- Sem amostras → `nil` (nunca 0).

### 3.5 Widget
- Timeline: uma entrada por dia do `DailyPlan`, na hora `changeHour`. Política `.atEnd`.
- Sem plano (app nunca aberto ou plano vencido): calcular entrada `geral` localmente com `DailyPicker` + `ContentLibrary` do bundle. **O widget nunca fica vazio.**
- Após qualquer mudança de plano: `WidgetCenter.shared.reloadAllTimelines()`.
- Toque abre `atletaestoico://today`.

### 3.6 Notificações
- Máximo **1 planejada + 1 de evento** por dia. Agendar os próximos 7 dias no `notificationHour` com o conteúdo do plano. Identificador: `"daily-yyyy-MM-dd"`. Reagendar = cancela todos os `"daily-*"` pendentes e recria.
- **sono_ruim**: sem notificação imediata. O conteúdo sono_ruim entra no aviso agendado da manhã (o plano já carrega o trigger). Se a hora já passou, nenhuma notificação.
- **pos_treino / retorno**: notificação imediata (`"now-yyyy-MM-dd"`, `UNTimeIntervalTrigger 1s`). Cancela `"daily-hoje"` pendente. `DeliveryLog.notified` marca que o evento foi notificado; segunda ocorrência no mesmo dia → nada.
- **Horário de silêncio 21h–7h**: notificação de evento (`pos_treino`/`retorno`) não dispara na hora. O conteúdo ainda vale para widget e app.
- **Permissão**: `.authorized`, `.provisional` e `.ephemeral` são aceitos. Sem permissão, não fazer nada e não mostrar erro.
- Toque abre `atletaestoico://today`. Corpo: `shortText + " — " + author`. Título por gatilho via String Catalog.

### 3.7 Papel de parede
- Resolução: tamanho da tela em pixels (`UIScreen.main.nativeBounds`), retrato.
- Composição: foto em `scaledToFill` + gradiente leve na área do texto + frase (`shortText`) e autor no terço central-inferior, cor pelo `tom` da imagem. Se `quoteOnWallpaper == false`, só a foto.
- Pré-gerar o arquivo do dia no App Group quando o plano é criado (o App Intent só lê o arquivo; não renderiza na hora).

---

## 4. Tarefas

Cada tarefa: **Objetivo · Arquivos · Passos · Aceite**. 🔍 = revisão com Opus antes de seguir.

### T00 — Setup do projeto
- **Arquivos:** `project.yml` (já existe), `Resources/Localizable.xcstrings` (pt-BR, en, es; incluir também no alvo do widget), `Sources/App/AtletaEstoicoApp.swift`, `RootView.swift`, `Shared/Theme.swift`, `Sources/Widget/AtletaEstoicoWidgetBundle.swift` (widget placeholder "Olá"), `Tests/SmokeTests.swift`.
- **Passos:** remover `.gitkeep` das pastas que receberem arquivos; conferir no `project.yml` (já configurados) HealthKit + background delivery, App Group nos dois alvos, URL scheme `atletaestoico`, `BGTaskSchedulerPermittedIdentifiers` e `NSPhotoLibraryAddUsageDescription`; preencher `DEVELOPMENT_TEAM`; `xcodegen generate`; build.
- **Aceite:** app abre no simulador com tela "AtletaEstoico" e mostra o texto traduzido ao trocar o idioma do simulador (pt/en/es); widget aparece na galeria de widgets; `test` passa.

### T01 — Conteúdo e ContentLibrary
- **Arquivos:** `Message.swift`, `ImageAsset.swift`, `ContentLibrary.swift`, `Trigger.swift`, `ImageCategory` (em `ImageAsset.swift`), `ContentLibraryTests.swift`.
- **Passos:** decodificar `Content/messages/base.json` + o arquivo do idioma resolvido por `ContentLocale` (pt-BR, en, es) e `Content/images_seed.json` (chaves em português → `CodingKeys`). `Message` final = metadados + textos do idioma + nome do autor/obra no idioma. `ContentLibrary.validate()` retorna lista de problemas.
- **Aceite (testes):** IDs únicos; **todo idioma de lançamento tem todos os IDs**; limites de texto por idioma de `base.json → limites_widget` (zh-Hans: 32/12); todo gatilho é um `Trigger` válido; todo autor e obra tem nome em cada idioma; toda imagem tem `licenca` e `tom`; fallback: idioma inexistente (ex.: `de`) carrega `en`.

### T02 — Sorteio determinístico
- **Arquivos:** `DayKey.swift`, `StableHash.swift`, `SeededGenerator.swift`, `DailyPicker.swift`, testes.
- **Passos:** FNV-1a 64 bits; SplitMix64; `DailyPicker.index` = embaralhar `0..<count` com Fisher–Yates usando `SeededGenerator(seed: fnv1a64("\(installID)|\(salt)|ciclo\(day.dayNumber / count)"))` e pegar a posição `day.dayNumber % count`.
- **Aceite (testes):** mesmo input → mesmo output (inclusive entre execuções: testar valor fixo esperado de `fnv1a64("abc")` = `0xe71fa2190541574b`); em `count` dias consecutivos do mesmo ciclo não há repetição; installIDs diferentes geram ordens diferentes.

### T03 — Persistência
- **Arquivos:** `Data/*.swift` (SwiftData `@Model`), `DailyPlan.swift`, `SharedStore.swift`, `SharedPreferences` (em `SharedStore.swift`).
- **Modelos:** `Race(name, date, distanceKm, category)`, `WeekPlan(sessions: [Int: SessionType])` (guardar como `[String]` de 7 posições, seg→dom), `AthleteProfile(why, mantra, sleepGoalHours, onboardingDone)`, `JournalEntry(day, controlled, notControlled, note)`, `DeliveryLog(day, messageID, imageID, trigger, notified)`.
- **Aceite:** teste grava e lê `DailyPlan` e `SharedPreferences` num diretório temporário (injetar URL base para testar sem App Group); `installID` gerado uma vez (UUID) e persistido.

### T04 — Onboarding
- **Arquivos:** `Features/Onboarding/*`.
- **Atenção (revisão T03):** `SharedStore.loadPreferences()` (cria installID) só no app; o widget usa `loadPreferencesIfExists()`. `JournalEntry` e `DeliveryLog` são únicos por dia: atualizar, não inserir de novo.
- **Telas:** (1) prova-alvo: nome, data, distância, categoria (trail/rua/trilha) — com opção "ainda não tenho prova"; (2) semana: 7 chips seg–dom, cada um alterna leve/forte/longo/descanso; (3) "por que você corre?" (texto livre, 140 caracteres) + mantra sugerido editável (no MVP: template "<Porquê>. Um passo de cada vez." — sem prefixo fixo, para evitar erro de concordância); (4) permissões: app Saúde e notificações, cada uma com explicação de 1 linha e botão "agora não".
- **Aceite:** fluxo completo grava os modelos; reabrir o app pula o onboarding; funciona negando todas as permissões.

### T05 — HealthKit
- **Arquivos:** `HealthDataProviding.swift`, `HealthKitService.swift`, `SleepCalculator.swift`, `WorkoutSummary`, `MockHealthProvider` (no target de testes), `SleepCalculatorTests.swift`.
- **Passos:** ler `HKObjectType.workoutType()` (filtrar `.running`, `.hiking`, `.walking` com distância > 3 km) e `.sleepAnalysis`; usar `HKSampleQueryDescriptor` (async); `HKObserverQuery` + `enableBackgroundDelivery(for: workoutType, frequency: .immediate)`.
- **Atenção:** o iOS não informa se o usuário negou leitura; trate "sem dados" como estado normal.
- **Aceite (testes):** sono com dois intervalos sobrepostos de fontes diferentes conta uma vez; `inBed` ignorado; sem amostras → `nil`. Rodar no iPhone físico e ver treinos do Garmin listados num log de debug.

### T06 — TriggerEngine 🔍
- **Arquivos:** `TrainingContext.swift`, `TriggerEngine.swift`, `ContextBuilder.swift`, `SessionType`, `TriggerEngineTests.swift`.
- **Aceite (testes):** um teste para cada regra da 3.1 **e** testes de conflito (ex.: T-7 da prova + sono ruim → marco_prova; pós-treino às 13h + sono ruim → pos_treino; sono ruim às 14h → não dispara). `TriggerEngine` é função pura (sem `Date()` interno; recebe `now`).
- **🔍 Revisão Opus:** prioridades e bordas de data/fuso.

### T07 — MessageEngine e personalização
- **Arquivos:** `MessageEngine.swift`, `ReflectionPersonalizer.swift`, `MessageEngineTests.swift`.
- **Passos:** implementar 3.2 e 3.3. `ReflectionPersonalizer` (protocolo) com `TemplatePersonalizer` (usa `reflexao` do JSON) e `FoundationModelsPersonalizer` (T13 — por ora só o stub atrás de `#if canImport`).
- **Aceite (testes):** grátis recebe sempre `geral`; gatilho com histórico de 30 dias não repete; filtro vazio cai no fallback; imagem da semana da prova é sempre da categoria da prova.

### T08 — DailyPlanner 🔍
- **Arquivos:** `DailyPlanner.swift`, `DailyPlannerTests.swift`.
- **Fluxo `refresh(now:)`:** montar contexto → gerar entradas de hoje + 6 dias (planejáveis) → aplicar gatilho de evento em hoje → gravar `DailyPlan` no `SharedStore` → gravar `DeliveryLog` de hoje → pré-gerar papel de parede de hoje (T12; por ora protocolo vazio) → `reloadAllTimelines` → reagendar notificações (T09; por ora protocolo).
- **Atenção (revisão T06):** (a) dias futuros do plano usam só gatilhos planejáveis: montar o contexto desses dias sem dados de evento (sono, treino), senão o sono de hoje contamina a semana; (b) gatilho de evento é **"pegajoso"**: depois que hoje virou pos_treino/sono_ruim/retorno, um refresh posterior no mesmo dia não pode rebaixar para planejado/geral (nem trocar a mensagem do widget no meio do dia, nem apagar o registro do pos_treino no DeliveryLog).
- **Atenção (revisão T05):** o `HKObserverQuery` hoje chama `completionHandler()` antes do trabalho terminar. No DailyPlanner, chamar o completion só depois do `refresh` concluir (senão o iOS pode suspender o app no meio). Garantir que `startObserving` seja chamado uma única vez.
- **Chamado em:** abertura do app (`scenePhase == .active`), observer do HealthKit, mudança de preferências, e `BGAppRefreshTask` diária (registrar identificador `com.atletaestoico.refresh`).
- **Aceite (testes com mocks):** plano tem 7 entradas com dias consecutivos; amanhã longo → hoje é `vespera_chave`; treino recém-detectado substitui hoje por `pos_treino` sem mexer nos outros dias.
- **🔍 Revisão Opus:** consistência app/widget/notificação e casos de app fechado por dias.

### T09 — Notificações
- **Arquivos:** `NotificationScheduler.swift` (+ protocolo para mock).
- **Aceite:** 7 notificações pendentes após `refresh`; nunca 2 no mesmo dia; pós-treino cancela a agendada do dia; título = gatilho legível ("Véspera de longão"), corpo = `shortText` + autor.

### T10 — Telas principais
- **Arquivos:** `Today`, `Race`, `Mantra`, `Journal` (TabView com 4 abas: Hoje, Prova, Mantra, Diário) + `Settings` acessível pela aba Hoje.
- **Hoje:** paisagem do dia no topo, frase completa (`texto`), autor e fonte, reflexão, botão "Revisão da noite" (abre `JournalEntrySheet` com 2 perguntas).
- **Prova:** contagem regressiva grande + marcos T-30/T-7/T-1/D0 (concluídos ficam marcados).
- **Mantra:** mantra em destaque, editar, botão copiar.
- **Diário:** lista de revisões por dia; contador de dias seguidos.
- **Settings:** hora de troca, hora da notificação, categorias de imagem, frase no papel de parede on/off, meta de sono, link para o guia do papel de parede, restaurar compras.
- **Aceite:** todas as telas com dados reais do plano; modo escuro ok; Dynamic Type até XL sem cortar texto; **as 3 línguas sem texto fixo e sem corte** (testar em espanhol, a mais longa das três); datas e distâncias formatadas pelo sistema (milhas em en-US).

### T11 — Widgets 🔍
- **Arquivos:** `Widget/*`.
- **Famílias:** `.accessoryRectangular` (shortText + "— autor", `minimumScaleFactor(0.8)`), `.accessoryInline` (inlineText), `.accessoryCircular` (dias para a prova com `Gauge`; sem prova → ícone), `.systemMedium` e `.systemLarge` (paisagem + frase + dias).
- **Obrigatório iOS 17:** `.containerBackground(for: .widget)`; `widgetURL(URL(string: "atletaestoico://today"))`.
- **Aceite:** widget com textos no idioma do aparelho (incluindo nomes de autor e textos de contexto); widget de bloqueio aparece no simulador (personalizar tela de bloqueio); muda ao alterar a data do simulador; sem plano mostra mensagem `geral` local.
- **🔍 Revisão Opus:** fallback sem plano, limites de texto, desempenho da timeline.

### T12 — Papel de parede + Atalhos
- **Arquivos:** `WallpaperComposer.swift`, `DailyWallpaperIntent.swift`, `Settings/WallpaperSetupGuide.swift`.
- **Passos:** compor com `ImageRenderer` (SwiftUI) na escala da tela; salvar PNG em `SharedStore.wallpaperURL(for:)` e apagar os PNGs com mais de 7 dias (senão acumulam no App Group); botão "Salvar na galeria" (`PHPhotoLibrary` só escrita); `AppIntent` "Papel de parede do dia" retornando `IntentFile` (PNG) com `openAppWhenRun = false`; `AppShortcutsProvider` com frase "Papel de parede do Fudōshin".
- **Guia (5 passos com imagens/texto):** Atalhos → Automação → Horário do dia → ação "Papel de parede do dia" → "Definir papel de parede" → desativar "Perguntar antes de executar".
- **Aceite:** no iPhone físico, uma automação criada manualmente troca o papel de parede sem abrir o app; arquivo do dia já existe antes do intent rodar; se não existir, o intent gera na hora.

### T13 — Foundation Models (opcional no beta)
- **Arquivos:** `FoundationModelsPersonalizer` em `ReflectionPersonalizer.swift`.
- **Passos:** `SystemLanguageModel.default.availability == .available`; `LanguageModelSession(instructions:)` com instruções: "Escreva 1 a 2 frases em português, tom direto, para um corredor. Use o porquê dele. Não cite autores. Não invente fatos sobre o treino." Entrada: gatilho, porquê, frase do dia **e idioma do conteúdo** (instruir a responder nesse idioma; se o modelo não suportar o idioma, usar o template). Limite 220 caracteres; se passar ou falhar, usa o template.
- **Aceite:** em aparelho sem Apple Intelligence o app funciona igual (template); reflexão gerada nunca contém aspas nem nome de filósofo (validar e descartar se contiver).

### T14 — Paywall e assinatura
- **Arquivos:** `Paywall/PaywallView.swift`, `EntitlementStore.swift`, `Products.storekit` (configuração local de teste).
- **Produtos:** `com.atletaestoico.anual` (assinatura anual) e `com.atletaestoico.vitalicio` (compra única). Preços definidos depois do teste da landing.
- **Grátis vs pago:** ver `PROJECT_CONTEXT.md` (grátis: mensagem geral, widget de bloqueio, 1 categoria de imagem; pago: contexto do treino, todas as categorias, frase no papel de parede, automação, trilhas de prova).
- **Aceite:** compra e restauração funcionam com o arquivo `.storekit` no simulador; `isPremium` reflete `Transaction.currentEntitlements` e é gravado em `SharedPreferences` (o widget lê de lá).

### T15 — Acabamento e TestFlight 🔍
- Ícone, tela de abertura, textos de permissão revisados, política de privacidade (link), App Privacy "Dados não coletados", screenshots.
- Testar no iPhone físico: 3 dias seguidos com Garmin sincronizando; widget trocando à meia-noite; automação do papel de parede.
- **🔍 Revisão Opus final:** checklist da diretriz 5.1.3 (HealthKit), privacidade e caminhos de erro.

---

## 5. Armadilhas conhecidas (ler antes de começar)
1. `Hasher`/`hashValue` muda a cada execução → quebra o sorteio. Use `StableHash`.
2. Widget com SwiftData do app dá problema de acesso concorrente → widget lê só o JSON do App Group.
3. App Group precisa estar ativo **nos dois alvos** e no Apple Developer (identificador idêntico).
4. HealthKit não diz se a leitura foi negada → nunca mostre erro por "sem dados".
5. Sincronização Garmin → app Saúde atrasa → gatilho pós-treino usa janela de 3h a partir do **fim** do treino, não da chegada do dado.
6. `BGAppRefreshTask` não tem horário garantido → o widget precisa funcionar sozinho (fallback local).
7. O iOS limita a 64 notificações pendentes → agendar só 7.
8. `ImageRenderer` precisa rodar na main actor.
9. FoundationModels só compila com Xcode 26 → manter atrás de `#if canImport(FoundationModels)`.
10. Citações: o modelo de código **não** deve completar, "corrigir" ou traduzir frases do JSON.
11. Idiomas: nunca montar frase concatenando pedaços traduzidos ("Faltam " + n + " dias") — usar String Catalog com variáveis e plural.
12. Arquivos dentro de `Content/` vão para o bundle do app e do widget: não colocar rascunhos lá (`_arquivo/` fica na raiz).

---

## 6. Conteúdo (trabalho paralelo, não é código)
- 120 mensagens verificadas na fonte em domínio público, em **3 idiomas** (fluxo em `Content/IDIOMAS.md`: rascunho com IA a partir do original + revisão nativa) (Project Gutenberg: Long, Gummere, Higginson). **Cada citação conferida por humano** contra o texto original antes de entrar no JSON.
- Haiku pode gerar *rascunhos* de `texto_curto`/`texto_inline` a partir de frases já verificadas; revisar todos.
- 30 imagens embarcadas, catalogadas em `images_seed.json`.

## 7. Estimativa
| Bloco | Tarefas | Sessões Sonnet (estim.) |
|---|---|---|
| Fundação | T00–T03 | 4–6 |
| Inteligência | T04–T09 | 8–12 |
| Superfícies | T10–T12 | 6–9 |
| Monetização e entrega | T13–T15 | 4–6 |
| **Total** | | **22–33 sessões** + 4 revisões Opus |
