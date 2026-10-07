# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** pendente
**Tarefa:** instalar o ícone do app (conceito C — samurai correndo)

Os arquivos já estão prontos em `Resources/Assets.xcassets/AppIcon.appiconset/`
(AppIcon.png 1024 sem transparência, AppIcon-dark.png e AppIcon-tinted.png para iOS 18, e Contents.json).

1. `project.yml`, target do app (AtletaEstoico): incluir `Resources/Assets.xcassets` nas sources e
   definir `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` nas settings. Não incluir no target do widget.
2. Rodar `xcodegen` e compilar. Corrigir qualquer aviso do asset catalog sobre o AppIcon.
3. Instalar no iPhone e conferir: ícone na tela inicial, nos Ajustes e na busca;
   no iOS 18, conferir também os modos Escuro e Tingido (pressionar a tela inicial → Editar → Personalizar).
4. Rodar todos os testes e fazer commit (`git add -A`, depois `git status` limpo):
   `feat: ícone do app (samurai correndo) com variantes escuro e tingido`
