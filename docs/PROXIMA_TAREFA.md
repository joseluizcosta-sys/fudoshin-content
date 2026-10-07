# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** concluída
**Tarefa:** ajustes da revisão da T16 (conteúdo remoto) + commit

1. `RemoteContentStore.checkForUpdate`: gravar `lastCheckKey` só depois de baixar e decodificar o manifesto com sucesso. Falha de rede = tenta de novo na próxima abertura do app.
2. Auto-recuperação: no início de `checkForUpdate`, se `activeVersion > 0` e (`currentContentDirectory == nil` ou `ContentLibrary(remoteContentDirectory:)` falhar), zerar `activeVersion` para permitir baixar de novo.
3. A URL do manifesto já foi ajustada no `project.yml` e no `Info.plist` para `https://joseluizcosta-sys.github.io/fudoshin-content/manifest.json`. Rode `xcodegen` se necessário.
4. Testes novos: (i) falha de rede não grava `lastCheck` (a próxima chamada tenta de novo); (j) pasta `current` apagada com `activeVersion = 5` → baixa de novo a v5.
5. Rodar todos os testes e fazer commit:
   `feat: T16 conteúdo remoto com manifesto versionado, validação e fallback embutido`
   Se o commit falhar com "File exists" por arquivo `.lock` em `.git`, rode `rm -f .git/*.lock .git/objects/maintenance.lock` e tente de novo.
