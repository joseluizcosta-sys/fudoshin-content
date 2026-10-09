# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça um commit por bloco.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.
> Antes de tudo: compile e confira os commits 851e4a2, 62a6a10 e a46410d do Opus (feitos sem compilar):
> RootView com estado `.unknown`, `Fudoshin.storekit` reescrito, PaywallView com `.background`, textos do paywall.

**Status:** pendente
**Tarefa:** papéis de parede publicados pelo mesmo caminho das frases (sem crescer o tamanho do app)

## Objetivo
JC gera imagens novas no Gemini, roda `tools/publicar.sh` e, em até 7 dias (ou na hora, pelo Debug), os assinantes
veem as imagens novas na galeria da aba Fundo — **sem versão nova na App Store**. As 5 imagens `Wallpaper_epico_1…5`
continuam embutidas como base offline; **imagens novas são só remotas**.

## Bloco 1 — Publicação (`tools/`)
- Pasta de origem: `Content/Wallpapers/` (JC solta lá os JPEG do Gemini, qualquer nome).
- Novo comando `python3 tools/content_sheet.py wallpapers` (ou script próprio `tools/wallpapers.py`, chamado pelo `publicar.sh`):
  1. Para cada imagem nova: redimensiona para **1290×2311 máx. (proporção mantida), JPEG qualidade 82**, nome
     `wp_<sha256[:12]>.jpg` (estável, sem duplicar); rejeita imagem menor que 1000 px de largura.
  2. Gera `dist/content/wallpapers.json`:
     `{"schema":1,"version":N,"items":[{"id":"wp_ab12…","file":"wallpapers/wp_ab12….jpg","sha256":"…","bytes":123,"added":"2026-10-09"}]}`
     — itens em ordem de inclusão; `version` sobe só quando a lista muda.
  3. `publicar.sh` copia `wallpapers.json` e os arquivos novos para `fudoshin-content/wallpapers/` e faz o commit/push junto
     com as frases. O preview mostra "N imagens novas". Imagem removida da pasta = removida do índice (o arquivo no site pode ficar).
- Não versionar os originais pesados no repositório do app: `Content/Wallpapers/` no `.gitignore`
  (guardar só `wallpapers.json` gerado em `dist/`).

## Bloco 2 — App: baixar e guardar
- `RemoteWallpaperStore` (actor), chamado junto com `RemoteContentStore.checkForUpdate` (mesma janela de 7 dias e mesmo
  botão "Buscar conteúdo agora" do Debug):
  1. Baixa `wallpapers.json` (mesma base de URL do manifesto); se `version` não mudou, para.
  2. Para cada item ainda não baixado: baixa, confere `bytes` e `sha256`, grava em
     `App Group/RemoteContent/wallpapers/<id>.jpg` (gravação atômica). Falha num item não derruba os outros.
  3. Limites: no máximo 40 imagens e 30 MB no total; itens além disso são ignorados.
  4. Remove do disco os ids que saíram do índice, **exceto** a imagem escolhida pelo usuário (ela fica até ele trocar).
  5. Grava o índice local só depois de baixar.
- Sem servidor novo: tudo estático no GitHub Pages, como as frases.

## Bloco 3 — App: catálogo único
- Substituir os nomes de asset por um catálogo: `WallpaperCatalog.entries() -> [WallpaperEntry]`, com
  `WallpaperEntry { id: String; source: .bundled(assetName) | .file(URL); isNew: Bool }`.
  Ordem: remotas mais novas primeiro, depois as embutidas. `isNew` = adicionada nos últimos 14 dias.
- `WallpaperImage.resolve/name(for:)` passam a trabalhar com ids do catálogo (sorteio diário continua estável:
  ordenar por id antes de sortear para não mudar quando chega imagem nova no meio do dia).
- Carregar imagem: `.bundled` → `UIImage(named:)`; `.file` → `UIImage(contentsOfFile:)`.
- Composer, aba Fundo (galeria) e preferência `wallpaperImage` usam o id. Preferências antigas com nome de asset
  (`Wallpaper_epico_3`) continuam válidas (o id das embutidas é o próprio nome).
- Galeria: selo pequeno "Nova" nas imagens com `isNew`.

## Testes
- Script: mesma imagem duas vezes → um item só; `version` só sobe se a lista mudar; redimensionamento correto.
- Store (com `MockURLProtocol`): baixa só o que falta; sha errado → descarta o item; remove ids que saíram, exceto o escolhido;
  respeita limites.
- Catálogo: junta embutidas + remotas; ordem; `isNew`; sorteio estável quando chega imagem nova.

## Commits
1. `feat(content): publicação de papéis de parede (wallpapers.json + imagens no GitHub Pages)`
2. `feat: RemoteWallpaperStore — baixa e guarda papéis de parede remotos`
3. `feat: catálogo único de papéis de parede (embutidos + remotos) na galeria, composer e Atalhos`

## Teste manual (JC)
1. Coloque 1 imagem nova em `Content/Wallpapers/`, rode `tools/publicar.sh`.
2. No iPhone: Debug → "Buscar conteúdo agora" → aba Fundo mostra a imagem com selo "Nova".
