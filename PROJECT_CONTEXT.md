# Fudōshin — Contexto do Projeto

> 不動心 · **O corpo se move. A mente, não.**

> Documento mestre. Nome do produto: **Fudōshin** (decidido em 03/10/2026). Codinome técnico: AtletaEstoico (pastas, bundle IDs, App Group). **Não usar "Daily Stoic"**, que é marca do Ryan Holiday.
> Criado em 28/09/2026 · Atualizado em 03/10/2026 (papel de parede diário, widget da tela de bloqueio e idiomas).

---

## Instruções sugeridas (se virar um Projeto Claude dedicado)

> Você é o conselheiro estratégico e parceiro técnico do **AtletaEstoico**, um app iOS nativo que entrega mensagens estoicas e de livros para atletas de endurance no momento certo do treino. O contexto vem do app Saúde (HealthKit) e da prova-alvo. Tudo roda no iPhone: sem backend na Fase 1. Seja crítico e aponte riscos, gargalos e custo marginal antes de propor features.

---

## 1. Tese

**Slogan:** *"O corpo se move. A mente, não."* · **Promessa:** *"A frase certa no momento certo do treino."*

O mercado de frases motivacionais está saturado e o conteúdo é commodity (Motivation – Daily quotes, vários apps "Daily Stoic"). Ninguém usa o **contexto do atleta** (treino feito, sono, proximidade da prova, lesão). Esse é o diferencial. Preço baixo sozinho não é um fosso.

**Ponto de contato diário:** a tela de bloqueio. O usuário vê o celular dezenas de vezes por dia, então um papel de parede com paisagem de corrida + a frase do dia mantém o app presente sem depender de notificação.

**Persona âncora:** corredor de rua ou trail (meia maratona até ultra) com Garmin ou Apple Watch, que treina para uma prova-alvo e já consome conteúdo de mentalidade.

---

## 2. Decisões tomadas

| # | Decisão | Por quê |
|---|---|---|
| D1 | Fase 1 **sem Garmin API** | A API oficial não lê a agenda futura, exige empresa e servidor. O app Garmin Connect já sincroniza atividades com o app Saúde |
| D2 | Contexto vem do **HealthKit + dados informados pelo usuário** (prova, dias-chave da semana) | Custo zero, sem aprovação de terceiros |
| D3 | **Zero backend** | Margem (custo marginal ~0), LGPD mais leve (dado de saúde não sai do aparelho) e argumento de marketing |
| D4 | Geração de texto com **Foundation Models on-device** (iOS 26+), com fallback para biblioteca curada | Personalização sem custo de API por usuário |
| D5 | Conteúdo só de **domínio público** ou texto próprio | Evita risco de direitos autorais (ver `Content/DIREITOS.md`) |
| D6 | **Validar antes de codar a fundo** (landing + lista de espera) | Categoria com retenção historicamente baixa |
| D7 | **Papel de parede diário** com paisagens de trail, rua e trilha + frase do dia (03/10/2026) | Presença diária na tela de bloqueio. Sozinho não diferencia (o Motivation já tem fundos), então a escolha da imagem também segue o contexto do treino |
| D8 | A troca automática do papel de parede é feita por **automação do app Atalhos**, não pelo app | O iOS não tem API pública para um app trocar o papel de parede. O app gera a imagem do dia e oferece uma ação de Atalhos |
| D9 | Imagens **próprias ou licenciadas por escrito**, sem pessoas identificáveis | Unsplash/Pexels são zona cinzenta para app que distribui fotos como produto. Ver `Content/IMAGENS.md` |
| D11 | **Widget da tela de bloqueio** com a mensagem do dia, trocando diariamente (03/10/2026) | Canal nativo, sem configuração de Atalhos, visto dezenas de vezes por dia. Vira o canal principal da mensagem; o papel de parede passa a ser complemento |
| D16 | **Nome na App Store: "Fudōshin: Mente Samurai"** (en "Fudōshin: Samurai Mindset", es "Fudōshin: Mente Samurái"); subtítulo "Motivação no momento certo". Nome no iPhone continua "Fudōshin" (06/10/2026) | Fudōshin segue como marca registrável e distintiva; "Mente Samurai" dá busca e entendimento imediato. Avaliadas e descartadas: TheRunnerMind (descritivo, espaço lotado), NinjaMindset (contradiz o conteúdo samurai, tom infantil, marca NINJA congestionada), Samurai como nome principal (conflito com o livro/newsletter *Samurai Running* e jogos "Samurai Runner"). Ver `docs/AppStore_Metadados.md` |
| D15 | **Autores contemporâneos do esporte (Goggins, Kipchoge) só como paráfrase**, exibidas como "Inspirado em <autor>" (03/10/2026) | Aproxima o conteúdo do atleta moderno sem risco de direito autoral; nomes e imagens fora do marketing. Ver `Content/DIREITOS.md`, regra 2b |
| D14 | **Conteúdo japonês:** Musashi (*Livro dos Cinco Anéis*, *Dokkōdō*) e Takuan Sōhō (*Fudōchi Shinmyōroku*), traduzidos do original japonês (03/10/2026) | Reforça a marca Fudōshin e o posicionamento "mente inabalável" (estoicos + samurais). Traduções modernas são protegidas; revisão por leitor de japonês clássico obrigatória |
| D13 | **Nome: Fudōshin (不動心), slogan "O corpo se move. A mente, não."** (03/10/2026) | Distinto na categoria, com história e ícone simples (ideograma). Posicionamento "mente inabalável" une estoicos e samurais. Pendências: teste do som em PT-BR, marca nas classes 9/41, revisão nativa dos ideogramas. Ver `docs/Marca_Fudoshin.md` |
| D12 | **3 idiomas no lançamento (pt-BR, en, es)**, estrutura pronta para de, fr, it, zh-Hans (03/10/2026) | Frases **armazenadas por idioma**, traduzidas na produção do conteúdo (IA + revisão nativa). Tradução em tempo real não roda no widget, não respeita limites de texto e pode distorcer a citação. Ver `Content/IDIOMAS.md` |
| D10 | **iOS 17 mínimo no MVP** (03/10/2026). 30 imagens embarcadas; Foundation Models só em iOS 26+ via `#available`; Background Assets depois do beta | Tira a decisão do caminho crítico e não perde usuários. Reversível |

---

## 3. Escopo do MVP (Fase 1)

**Dentro:**
1. **Onboarding de 60s:** prova-alvo (nome, data, distância), dias de treino longo, forte e descanso, e o "porquê" do atleta.
2. **Motor de contexto:** lê treinos e sono do app Saúde e decide o gatilho do dia.
3. **Mensagem do dia + notificação contextual** (pré-treino-chave, pós-treino, descanso, sono ruim).
4. **Contagem regressiva da prova** com trilha mental nos marcos T-30, T-7, T-1 e dia da prova.
5. **Mantra pessoal** montado a partir do "porquê".
6. **Revisão estoica noturna** de 60s ("o que controlei / o que não controlei").
7. **Widgets:**
   - **Tela de bloqueio:** mensagem do dia (troca diária), linha acima do relógio e contagem regressiva da prova. Ver 4c.
   - **Tela inicial:** paisagem do dia + frase + dias para a prova.
8. **Papel de parede diário:** uma paisagem por dia (trail, rua ou trilha), escolhida de forma aleatória e sem repetição, com a frase do dia aplicada sobre a imagem. Troca automática via app Atalhos e opção de salvar na galeria.
9. **Idiomas:** interface e conteúdo em português, inglês e espanhol, seguindo o idioma do iPhone. Novos idiomas entram adicionando um arquivo, sem mudar código.

**Fora (Fase 2+):** fotos enviadas pelos usuários (com moderação), packs de paisagens de provas famosas, Apple Watch, Intervals.icu, TrainingPeaks, Garmin API, modo lesão/DNF completo, social, Android.

---

## 4. Matriz de gatilhos

| Gatilho | Sinal | Fonte | Tom da mensagem |
|---|---|---|---|
| Véspera de treino-chave | Dia marcado como longo ou forte | Usuário | Preparação, foco no processo |
| Pós-treino | Novo `HKWorkout` de corrida | HealthKit | Reflexão curta + pergunta do diário |
| Sono ruim | Sono < meta do usuário | HealthKit | Aceitar e ajustar, não "vai com tudo" |
| Descanso | Dia marcado como descanso | Usuário | Paciência, recuperação é treino |
| Marco da prova | T-30, T-7, T-1, D0 | Usuário | Trilha progressiva de preparação mental |
| Sem treino há X dias | Ausência de `HKWorkout` | HealthKit | Recomeço sem culpa |

Regra: **no máximo 1 notificação por dia**, sempre no horário configurado ou até 2h depois do treino detectado.

---

## 4b. Papel de parede diário

**Base de imagens (3 categorias):**

| Categoria | O que entra | Exemplos |
|---|---|---|
| `trail` | Montanha, single track, altitude, terreno técnico | Cristas, picos, trilhas de serra, nascer do sol em altitude |
| `rua` | Corrida urbana | Avenidas vazias ao amanhecer, orlas, pontes, parques urbanos |
| `trilha` | Natureza mais próxima e plana | Mata, bosque, estrada de terra, cachoeiras, campos |

**Como a imagem do dia é escolhida:**
1. Sorteio 1 vez por dia, com semente = data + ID da instalação. App, widget e Atalhos mostram a mesma imagem.
2. Peso por categoria segundo a preferência do usuário (padrão: o tipo da prova-alvo pesa mais).
3. Sem repetir imagem nos últimos 60 dias.
4. **Ligação com o contexto:** semana da prova puxa imagens do tipo da prova; dia de descanso puxa cenas com tag `calma`; véspera de longão puxa tag `epico`.
5. A frase do dia vem do motor de mensagens e é aplicada na área segura da imagem (fora do relógio e dos botões da tela de bloqueio), com cor do texto definida pelo tom da foto.

**Como chega à tela de bloqueio:**
- O app gera a imagem final (foto + frase) na resolução do aparelho e grava no contêiner compartilhado (App Group).
- Uma **ação de Atalhos** ("Papel de parede do dia") devolve essa imagem. O usuário instala, uma vez, uma automação diária (ex.: 5h) que roda a ação + "Definir papel de parede". O onboarding guia isso com um link de atalho pronto.
- Alternativas sem automação: botão "Salvar na galeria" e o widget da tela inicial.

**Armazenamento:** ~30 imagens no app (primeiro uso offline). O restante em pacotes hospedados pela Apple (Background Assets, iOS 26+), sem servidor próprio. Se o iOS mínimo ficar abaixo de 26, a alternativa é um bucket estático barato (ex.: Cloudflare R2), sem dado de usuário.

**Monetização:** grátis = 1 categoria e imagem sem frase personalizada. Pago = todas as categorias, frase do contexto e automação.

---

## 4c. Widget da tela de bloqueio

| Formato (WidgetKit) | Conteúdo | Limite de texto |
|---|---|---|
| Retangular (`accessoryRectangular`) | Mensagem do dia + autor | `texto_curto` ≤ 70 caracteres (~3 linhas) |
| Linha acima do relógio (`accessoryInline`) | Mantra ou frase-relâmpago do dia, ou "Longão amanhã" em dia de contexto | `texto_inline` ≤ 25 caracteres |
| Circular (`accessoryCircular`) | Dias para a prova (ex.: "27d") | — |

**Regras:**
1. **Troca diária** no horário escolhido pelo usuário (padrão 0h). A linha do tempo do widget já agenda os próximos 7 dias, então a troca acontece mesmo sem abrir o app.
2. **Mesma mensagem** em widget, notificação e papel de parede do dia (mesma semente diária, definida em `Core/Daily`). Quando houver gatilho de contexto (pós-treino detectado, sono ruim), o app pede atualização do widget na hora.
3. **Sem texto duplicado na tela de bloqueio:** com o widget ativo, o papel de parede sai sem frase por padrão (só a paisagem). O usuário pode mudar.
4. A tela de bloqueio mostra o widget em monocromático/translúcido: o visual vem da tipografia, não da cor.
5. Toque no widget abre a tela Hoje (reflexão completa + revisão noturna).
6. Cada mensagem da biblioteca precisa ter `texto_curto` e `texto_inline`. Frase que não cabe não entra no widget.

**Monetização:** widget da tela de bloqueio **grátis**. É o que mantém o app presente todo dia e alimenta a conversão. O pago destrava a mensagem por contexto do treino no widget (no grátis, mensagem diária geral).

**Bônus para a Fase 2:** os mesmos formatos `accessory` servem de complicação no Apple Watch com pouco código extra.

---

## 4d. Idiomas

- **Lançamento:** pt-BR, en, es. **Expansão:** de, fr, it, zh-Hans.
- **Conteúdo armazenado por idioma** (`Content/messages/<idioma>.json`, mesmos IDs). Tradução feita na produção: rascunho com IA a partir do texto em domínio público + revisão por nativo.
- **Em tempo real**, a IA do aparelho só escreve a reflexão personalizada no idioma do usuário. Citação nunca é traduzida no aparelho.
- **Interface** no String Catalog do Xcode desde o início; idioma segue o do iPhone (o iOS já permite trocar por app).
- **Ganho de mercado:** página da App Store localizada por país amplia o alcance de busca (ASO) em EUA, Espanha e América Latina.
- Detalhes, limites de texto por idioma e fluxo de tradução: `Content/IDIOMAS.md`.

---

## 5. Arquitetura

**Stack:** Swift / SwiftUI · HealthKit · SwiftData · UserNotifications · WidgetKit · App Intents (Atalhos) · Background Assets · FoundationModels (iOS 26+, opcional) · StoreKit 2.

```
Sources/
├── App/                 # entry point + navegação
├── Core/
│   ├── Health/          # HealthKitService: permissões, workouts, sono, observer query
│   ├── Context/         # TrainingContext + TriggerEngine (decide o gatilho do dia)
│   ├── Messages/        # MessageEngine: seleção na biblioteca + geração on-device
│   ├── Notifications/   # agendamento, limite de 1/dia
│   ├── Daily/           # semente diária e escolha do dia (mensagem + imagem), compartilhado com o widget
│   └── Wallpaper/       # composição foto + frase, ação de Atalhos (App Intent)
├── Widget/              # extensão WidgetKit: tela de bloqueio (retangular, inline, circular) e tela inicial
├── Data/                # SwiftData: Race, WeekPlan, Mantra, JournalEntry, DeliveredMessage
├── Features/            # Onboarding, Today, Race, Mantra, Journal
└── Shared/              # tema, componentes
Content/                 # messages/ (base + 1 arquivo por idioma), catálogo de imagens, regras de direitos e idiomas
└── Images/              # trail/, rua/, trilha/ (somente as ~30 imagens embarcadas)
```

**Atenção técnica:**
- A sincronização Garmin → app Saúde atrasa (minutos a horas). O gatilho pós-treino deve tolerar isso.
- Foundation Models só roda em aparelhos com Apple Intelligence (iPhone 15 Pro ou mais novo) e iOS 26+. A **biblioteca curada é o produto base**, e a IA é camada extra.
- App e widget compartilham dados por **App Group** (`group.com.atletaestoico`). O widget não lê o HealthKit: lê o "plano do dia" que o app grava.
- A entrega em segundo plano (`HKObserverQuery` + background delivery) não é garantida pelo iOS. Tenha fallback: gerar a mensagem ao abrir o app ou o widget.

---

## 6. Modelo de receita (hipótese a validar)

**Condição de fundador (lista de espera): 50% no 1º ano do plano anual.** Grátis: mensagem do dia + contagem regressiva. Pago: gatilhos por contexto, mantra, diário, trilhas de prova. Faixa de teste: anual baixo (~US$ 14,99–19,99/ano) ou compra única. Sem assinatura semanal.

---

## 7. Métricas e critérios de decisão

| Gate | Métrica | Seguir se |
|---|---|---|
| Validação (landing) | Inscritos / conversão | ≥ 300 inscritos **ou** ≥ 5% de conversão |
| Beta (TestFlight) | Retenção D7 | ≥ 35% |
| Lançamento | Retenção D30 | ≥ 15% |
| Lançamento | Teste → pago | ≥ 4% |

**North Star:** dias por semana em que o usuário abre a mensagem **e** faz a revisão noturna.

---

## 8. Riscos

1. **Retenção baixa** (categoria). Mitigar com diário + gatilhos + mantra.
2. **Direitos autorais** em citações de livros modernos. Só domínio público ou paráfrase própria com crédito.
3. **Foco do portfólio:** o app não reaproveita código da família Scanly nem compartilha persona. Tratar como aposta com prazo.
4. **Dependência da sincronização** Garmin → app Saúde.
5. **Automação do papel de parede depende do app Atalhos.** Exige um passo de configuração do usuário e pode quebrar em atualizações do iOS. Medir quantos completam a configuração; ter salvar na galeria e widget como alternativa.
6. **Custo e direitos das imagens.** 90–120 fotos boas custam tempo (fotos próprias) ou dinheiro (licença de fotógrafos). Imagem com pessoa identificável ou marca exige autorização.
7. **Papel de parede é recurso comum na categoria.** Ajuda a reter, não a diferenciar. O diferencial continua sendo o contexto do treino.
8. **Custo de cada idioma é a revisão, não a tradução.** Sem revisor nativo, uma frase estoica mal traduzida destrói a credibilidade. Lançar só com os idiomas revisados.
9. **Revisão da Apple:** dado de saúde não pode ser usado para anúncio nem sair do aparelho sem consentimento (diretriz 5.1.3).

---

## 9. Próximos passos

Plano de validação: `docs/Plano_Fase1.md`. Plano de código (tarefas T00–T15): `docs/BUILD_PLAN.md`. Regras para o modelo de código: `CLAUDE.md`.
