# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça um commit por bloco.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.
> Antes de tudo: compile e confira os commits f7ef06c (publicar.sh) e 3ee8407 (Debug) do Opus (feitos sem compilar).

**Status:** concluída

## T15 — Acabamento (parte 1: código). TestFlight vem na parte 2.

### Bloco A — Tirar do app o que não é conteúdo de execução (tamanho do app)
`project.yml` empacota a pasta `Content/` inteira **no app e no widget**. Hoje isso leva `Frases_Fudoshin.numbers` (~900 KB), os `.md` e, no futuro, as imagens-fonte de `Content/Wallpapers/` (vários MB cada) — duas vezes. Isso anula o ganho dos papéis de parede remotos.
1. Criar `ContentSource/` na raiz e mover para lá (com `git mv`): `Frases_Fudoshin.numbers`, `DIREITOS.md`, `IDIOMAS.md`, `IMAGENS.md`, `Wallpapers/`.
2. Em `Content/` ficam só: `messages/`, `images_seed.json`, `Images/`.
3. Atualizar caminhos em `tools/content_sheet.py`, `tools/wallpapers.py`, `tools/publicar.sh` (linha `git add …`), `.gitignore` (`ContentSource/Wallpapers/`), `CLAUDE.md`, `PROJECT_CONTEXT.md`, `docs/*` e testes Python.
4. Atualizar a armadilha 12 do BUILD_PLAN.
5. Conferir: build Release → tamanho do `.app` antes/depois no resumo. Nenhum `.numbers`/`.md`/`.jpeg` de fonte dentro do bundle (`find …/Fudoshin.app -name "*.numbers" -o -name "*.md"`).

### Bloco B — Paywall offline
Sem internet, `Product.products` falha e o paywall fica sem preço para sempre.
- Mostrar estado "Sem conexão — tentar de novo" com botão; recarregar sozinho quando a rede voltar (`NWPathMonitor`) e ao voltar para o app (`scenePhase == .active`).
- Botão "Restaurar compras" sempre visível (exigência da Apple), também offline.
- Teste unitário do estado de erro com produto mockado.

### Bloco C — Atalho/Siri e intent
1. Frases do `AppShortcutsProvider` estão só em inglês → adicionar pt-BR e es no String Catalog (`AppShortcuts.xcstrings` ou equivalente). Cada frase precisa conter `\(.applicationName)`.
2. `DailyWallpaperIntent` falha se o usuário passar 7+ dias sem abrir o app (plano expirado). O intent deve gerar o plano do dia sozinho a partir da biblioteca local (embutida + remota já baixada), sem HealthKit se não houver permissão em segundo plano. Teste: plano de 8 dias atrás → intent devolve imagem do dia de hoje.

### Bloco D — Textos de permissão e privacidade
1. Revisar `NSHealthShareUsageDescription` em pt/en/es (InfoPlist.xcstrings), claro e específico (treinos e sono, para escolher a mensagem; dados ficam no iPhone).
2. Ajustes → seção "Sobre": links "Política de privacidade" e "Termos de uso (EULA Apple)" usando `Links.privacyURL`/`Links.termsURL`; versão do app.
3. Garantir que nenhum dado sai do aparelho além dos GET ao GitHub Pages (sem analytics, sem logs remotos). Listar no resumo todas as URLs de rede do app.

### Bloco E — Personalizador (Foundation Models)
Revisar o personalizador: atrás de `#if canImport(FoundationModels)` e de checagem de disponibilidade; timeout curto (≤ 3 s) com fallback para o texto original; **nunca altera citações** (só texto de contexto). Teste com mock que demora 10 s → app usa o texto original.

### Fora do escopo
Não mexer em StoreKit/preço/trial (testado e aprovado pelo JC). Não renumerar tarefas do BUILD_PLAN.
