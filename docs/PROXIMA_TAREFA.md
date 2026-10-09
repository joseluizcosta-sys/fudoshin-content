# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça um commit por bloco.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** pendente

## Revisão Opus dos papéis de parede remotos — compilar e validar

O Opus corrigiu (sem compilar) o commit mais recente "fix(wallpapers): …". Compile, rode TODOS os testes e corrija o que quebrar, sem mudar o comportamento abaixo:

1. **URL do índice errada (bloqueante).** O app buscava `…/fudoshin-content/wallpapers/wallpapers.json`, mas o `publicar.sh` grava em `…/fudoshin-content/wallpapers.json`. Agora o app busca na raiz e baixa cada imagem por `item.file` (relativo à raiz, ex.: `wallpapers/wp_x.jpg`), recusando caminhos com `..` ou `/` inicial.
2. **Limite de 40 / 30 MB priorizava os mais antigos.** Agora percorre do mais novo para o mais antigo. Teste de bytes reescrito para verificar pelas URLs pedidas (`MockURLProtocol.requestedURLs`, novo).
3. **Imagem escolhida que sai do índice** ficava no disco mas sumia do índice local → catálogo não via → preferência caía no sorteio. Agora é mantida no índice local. Teste ganhou essa verificação.
4. **Download parcial** marcava a versão como aplicada → imagens que falharam nunca voltavam. Agora só grava a versão se tudo chegou; senão limpa `lastCheckDate` para tentar de novo na próxima abertura.
5. `.gitignore`: `__pycache__/`.

Teste extra a adicionar: índice com 1 item cujo download falha → `remoteWallpapers.version` continua 0; segunda chamada (sem `force`) tenta de novo.

Não renomeie nada no BUILD_PLAN: a tarefa anterior foi rotulada "T15" por engano nos docs; a T15 real (acabamento e TestFlight) continua pendente. Corrija só a menção em `docs/` se houver.
