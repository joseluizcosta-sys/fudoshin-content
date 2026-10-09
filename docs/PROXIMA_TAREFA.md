# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça os commits pedidos.
> Ao terminar, troque o status para "concluída", atualize a tabela de status do `docs/BUILD_PLAN.md` (T12)
> e resuma em 3 linhas o que mudou. Se algo da API do iOS não se comportar como descrito, pare e explique.

**Status:** concluída
**Tarefa:** T12 (papel de parede do dia + Atalhos) e widget mais legível na tela de bloqueio

## Bloco 1 — Papel de parede do dia (T12, ver BUILD_PLAN)

### 1.1 Composição (`Sources/Core/Wallpaper/WallpaperComposer.swift`)
- Implementar `WallpaperComposer: WallpaperComposing` e trocar o `NoOpWallpaperComposer` no `AppEnvironment`.
- Tamanho = tela nativa do aparelho, retrato (`UIScreen.main.nativeBounds`); injetável nos testes.
- Camadas, com `ImageRenderer` em escala 1 e tamanho em pixels:
  1. Imagem do gatilho: `HeroImage.name(for: entry.trigger)` (mesmo fallback da tela Hoje), `scaledToFill`, alinhada ao topo.
  2. Degradê preto de baixo para cima cobrindo os 50% inferiores (opacidade 0 → 0,85).
  3. Frase (`shortText`) em serif semibold branca, alinhada à esquerda, margens laterais de 7% da largura,
     tamanho ≈ 7% da largura (≈ 30 pt num 1290 px), até 4 linhas, `minimumScaleFactor(0.8)`.
     Abaixo dela, a atribuição (`attributionText`) em 55% do tamanho, branco 75%.
  4. Bloco de texto entre 58% e 86% da altura: **nada nos 30% de cima** (relógio) **nem nos 12% de baixo** (lanterna e câmera).
- Sem ideogramas no papel de parede (o relógio ocupa o lugar).
- Salvar PNG em `SharedStore.wallpaperURL(for:)` e apagar os `wallpaper_*.png` com mais de 7 dias.
- `prepareWallpaper(for:)` já é chamado pelo `DailyPlanner` a cada refresh; regerar só se o arquivo do dia não existir
  ou se `messageID`/`trigger` mudaram (guardar um sufixo ou um JSON pequeno ao lado).

### 1.2 Ação no app Atalhos (`Sources/App/DailyWallpaperIntent.swift`, alvo do app)
- `AppIntent` "Papel de parede do dia" (`openAppWhenRun = false`) que devolve `IntentFile` PNG do dia;
  se o arquivo não existir, gera na hora a partir do `SharedStore.loadPlan()`.
- `AppShortcutsProvider` com a frase "Papel de parede do \(.applicationName)" (pt/en/es no String Catalog).

### 1.3 Tela em Ajustes (`Sources/Features/Settings/WallpaperSetupGuide.swift`)
- Nova seção "Papel de parede" em Ajustes com: miniatura do papel de parede de hoje, botão **"Salvar no Fotos"**
  (`PHPhotoLibrary.requestAuthorization(for: .addOnly)`; a chave `NSPhotoLibraryAddUsageDescription` já existe)
  e botão **"Trocar automaticamente todo dia"**, que abre o guia.
- Guia em 5 passos (texto + ícones SF Symbols): Atalhos → Automação → Horário do dia (sugerir 5h) →
  ação "Papel de parede do dia" do Fudōshin → ação "Definir papel de parede" → desativar "Perguntar antes de executar".
  Usar o mesmo padrão `sheet(item:)` de Ajustes.
- Commit: `feat(T12): papel de parede do dia — composição, Salvar no Fotos, ação no Atalhos e guia`

## Bloco 2 — Widget da tela de bloqueio mais legível

- Renomear os estilos no String Catalog (pt/en/es):
  `destaque` → **"Frase completa"**, `palavraChave` → **"Frase grande"**. Não mudar os rawValues (o iOS guarda a escolha).
- `palavraChave`: fonte 22 bold, `lineLimit(2)`, `minimumScaleFactor(0.85)`.
- `destaque`: manter 16 semibold e 3 linhas, `minimumScaleFactor(0.8)`.
- Adicionar `.systemSmall` (vale para tela inicial e StandBy): `inlineText` grande, centralizado, com 不動心 pequeno embaixo.
- Em Ajustes, seção "Widget" com instruções curtas:
  "Segure o dedo na tela de bloqueio → Personalizar → Tela Bloqueada → toque no widget do Fudōshin → escolha 'Frase grande'."
  e uma linha sobre o StandBy (iPhone carregando deitado).
- Commit: `feat: widget — estilo Frase grande, tamanho pequeno/StandBy e instruções em Ajustes`

## Testes (obrigatórios)
- Composer: imagem gerada tem exatamente o tamanho pedido; arquivo salvo no URL do dia; arquivos com mais de 7 dias apagados;
  não regera se `messageID`/`trigger` iguais; regera se mudarem.
- Intent: devolve o arquivo existente; gera quando falta.
- `LockScreenContent` sem regressão.

## Teste manual (no iPhone, para o JC)
1. Ajustes → Papel de parede → Salvar no Fotos → conferir no app Fotos.
2. Criar a automação seguindo o guia, rodar manualmente uma vez e ver o papel de parede trocar.
3. Tela de bloqueio → widget → estilo "Frase grande".
