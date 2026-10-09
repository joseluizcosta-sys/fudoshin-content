# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** concluída
**Tarefa:** usuário escolhe a imagem do papel de parede (ou "Muda todo dia")

## 1. Preferência (`SharedPreferences`)
- Novo campo `wallpaperImage: String?` — `nil` = "Muda todo dia" (sorteio atual, padrão);
  um nome (ex.: `"Wallpaper_epico_3"`) = imagem fixa escolhida.
- Decodificação tolerante como os outros campos (JSON antigo → `nil`). Fica no App Group, porque a ação do Atalhos lê.

## 2. `WallpaperImage` / `WallpaperComposer`
- Nova função pura: `resolve(preference: String?, day:, installID:, exists:) -> String?`
  - preferência válida (o asset existe) → ela;
  - preferência inválida (asset removido) ou `nil` → sorteio diário atual.
- O composer usa `resolve`. A frase continua mudando todo dia; só a imagem fica fixa quando escolhida.
- Ao mudar a preferência, regerar o papel de parede de hoje na hora (o cache já compara o nome da imagem).

## 3. Aba Fundo — galeria
- Abaixo da prévia grande: título "Escolha a imagem" e um **carrossel horizontal** de miniaturas (proporção da tela,
  ~90 pt de largura, cantos arredondados):
  1. primeiro item **"Muda todo dia"** (ícone `shuffle` sobre fundo escuro);
  2. depois cada `Wallpaper_epico_N` disponível.
- Item selecionado com borda `Theme.accent` de 3 pt e um check. Toque → salva a preferência, regera e atualiza a prévia.
- Os botões "Salvar no Fotos" e "Trocar todo dia automaticamente" continuam abaixo.
- Texto do guia/dica: "Com uma imagem escolhida, a automação troca só a frase; com 'Muda todo dia', troca as duas."

## Testes
- `resolve`: preferência válida → ela; inválida → sorteio; `nil` → sorteio.
- Preferência salva e lida do JSON; JSON antigo sem o campo → `nil`.
- Composer regera quando a preferência muda.

## Commit
`feat: escolha da imagem do papel de parede (galeria na aba Fundo) ou "Muda todo dia"`
