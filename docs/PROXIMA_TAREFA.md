# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** pendente
**Tarefa:** ajustes de produto (Diário, Mantra, debug, horário de troca, imagem por momento)

Decisões do JC em 08/10/2026. Faça em commits separados, um por item, rodando os testes a cada um.

### 1. Diário — incluir e editar notas
- `JournalView`: botão "+" na toolbar abre `JournalEntrySheet` para uma nova entrada **de hoje**
  (se já existir a de hoje, abre a de hoje para editar — uma entrada por dia, como hoje).
- `JournalEntrySheet`: adicionar campo de **nota livre** (TextField multilinha) além das perguntas; as perguntas ficam opcionais.
  Se o modelo SwiftData da entrada não tiver campo de nota, adicionar `var note: String = ""` (default na declaração, para migração leve).
- Tocar numa entrada da lista abre para editar. Arrastar para apagar (swipe), com confirmação.
- Testes: criar, editar e apagar entrada; nota persiste; modelo antigo sem `note` carrega.
- Commit: `feat: diário com nota livre, edição e exclusão`

### 2. Remover a aba Mantra (o mantra continua)
- `MainTabView`: remover a aba Mantra → 3 abas (Hoje, Prova, Diário). Apagar `Features/Mantra/MantraView.swift` só se nada mais usar.
- Tela Hoje: linha discreta abaixo do crédito da frase e acima da reflexão: ícone `quote.opening` + o mantra do perfil
  (`AthleteProfile.mantra`) em `Theme.secondaryText`, 1–2 linhas. Se vazio, não mostrar nada.
- Ajustes: nova linha "Meu mantra" que abre um editor (TextField + Salvar), reaproveitando a lógica do MantraView (copiar não é necessário).
- Remover chaves de string órfãs da aba (tab.mantra etc.) do String Catalog.
- Commit: `feat: mantra na tela Hoje e em Ajustes; remove aba Mantra`

### 3. Tela de debug
- `HealthDebugView`: botão "Fechar" (toolbar, `topBarTrailing`) que faz `dismiss()`.
- Confirmar que o botão do estetoscópio e a tela só existem em `#if DEBUG` (já está no TodayView; conferir outros pontos de entrada).
- Commit: `fix: botão fechar na tela de debug`

### 4. Horário de troca fora dos Ajustes
- `SettingsView`: remover o controle de `changeHour`.
- Fixar `changeHour = 4` (constante em `SharedPreferences`, default 4). Na migração, quem tiver outro valor salvo passa a 4.
- Planner, widget e BGTask continuam lendo `prefs.changeHour` (sem mudança de lógica).
- Commit: `refactor: horário de troca fixo em 4h, fora dos Ajustes`

### 5. Imagem por momento (gatilho)
- Na tela Hoje, a imagem do topo depende do gatilho do dia:
  nome do asset `Hero_<gatilho>` (ex.: `Hero_pos_treino`, `Hero_vespera_chave`, `Hero_descanso`, `Hero_sono_ruim`,
  `Hero_retorno`, `Hero_marco_prova`, `Hero_geral`).
- Se o asset não existir, usar `HeroSamurai` (hoje é a única imagem). Criar função pura
  `HeroImage.name(for trigger: Trigger, available: (String) -> Bool) -> String` com testes
  (existe → usa; não existe → HeroSamurai).
- Não criar os 7 imagesets vazios; o JC vai adicionar as imagens aos poucos (vertical 9:16, ~1536×2752, JPEG).
- Documentar em `Content/IMAGENS.md` a convenção de nomes.
- Commit: `feat: imagem do topo por momento do treino, com fallback`

Ao final: instalar no iPhone e conferir as 3 abas, o diário (nova nota, editar, apagar) e Ajustes (mantra, sem horário de troca).
