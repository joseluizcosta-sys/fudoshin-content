# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** concluída
**Tarefa:** (1) sheets de Ajustes que abrem e fecham sozinhas; (2) ordem da tela Hoje

### 1. Bug: "Meu mantra", "Editar prova" e "Editar semana" abrem e fecham sozinhas
Causa provável (SettingsView.swift): quatro `.sheet(isPresented:)` presos a `Section`s **dentro do `Form`**.
Linhas de Form/List são recriadas a cada mudança do `vm` (e o próprio SettingsView já é uma sheet),
então a sheet filha é desmontada logo após abrir. Correção:
- Criar `enum SettingsSheet: String, Identifiable { case syncGuide, mantra, race, week; var id: String { rawValue } }`
  e um único `@State private var activeSheet: SettingsSheet?`.
- Os botões só fazem `activeSheet = .race` etc.
- **Um único** `.sheet(item: $activeSheet)` preso ao `NavigationStack` (fora do `Form`), com `switch` para
  SyncGuideView / MantraEditorSheet / RaceEditView / WeekEditView (mantendo os callbacks de refresh atuais).
- Remover os `.sheet` das `Section`s.
- Conferir o mesmo padrão em TodayView (Settings/Journal/Debug): trocar por um único `.sheet(item:)` com enum também.
- Teste manual obrigatório no iPhone: abrir e fechar cada uma das 4 telas de Ajustes, e salvar em cada uma.
- Commit: `fix: sheets de Ajustes com sheet(item:) único (não fecham mais sozinhas)`

### 2. Ordem da tela Hoje
Nova ordem, de cima para baixo:
1. Imagem (como está).
2. Bloco da frase: contexto do dia → frase → autor → obra · ref.
3. **Reflexão logo abaixo da frase**, sem `Divider` entre elas e sem o `SyncHintBanner` no meio
   (mesmo bloco visual, espaçamento ~12 pt; rótulo "REFLEXÃO" pequeno como hoje).
4. Botão "Revisão da noite" (como está).
5. `SyncHintBanner` (quando aparecer).
6. **Mantra no fim da tela**: tirar do bloco da frase e colocar por último, centralizado ou alinhado à esquerda,
   ícone `quote.opening` + texto em `Theme.secondaryText`, `.font(.callout)`, até 2 linhas; padding inferior para não colar na tab bar.
- Commit: `feat: tela Hoje — reflexão logo abaixo da frase e mantra no fim`
