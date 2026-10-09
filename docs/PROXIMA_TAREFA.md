# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** pendente
**Tarefa:** papel de parede usa as fotos épicas (`Wallpaper_epico_N`), sorteadas por dia

## Contexto
O Opus já instalou 5 imagens em `Resources/Assets.xcassets/Wallpaper_epico_1…5.imageset` (1536×2752, JPEG).
São fotos cinematográficas feitas **só para a tela de bloqueio**: samurai pequeno embaixo, céu calmo em cima,
meio livre para a frase. A tela Hoje continua com as ilustrações `Hero_<gatilho>` (não mexer).

## 1. `Sources/Core/Wallpaper/WallpaperImage.swift` (novo, função pura)
```swift
enum WallpaperImage {
    static let prefix = "Wallpaper_epico_"
    static let maxProbe = 99
    /// Nomes disponíveis em ordem (1, 2, 3…), parando no primeiro que faltar.
    static func available(_ exists: (String) -> Bool) -> [String]
    /// Escolha determinística por dia: mesma imagem o dia inteiro; dias seguidos não repetem
    /// quando houver ≥ 2 imagens. Sem imagens → nil (o composer usa HeroImage como hoje).
    static func name(for day: DayKey, installID: String, exists: (String) -> Bool) -> String?
}
```
- Usar o hash estável que já existe no projeto (`StableHash`) com `installID + day.value`, para usuários
  diferentes verem imagens diferentes no mesmo dia.
- "Dias seguidos não repetem": se a escolha de hoje for igual à de ontem, pegar a próxima da lista.
- Imagens novas (`Wallpaper_epico_6`, `_7`…) entram no sorteio sem mudar código.

## 2. `WallpaperComposer`
- Camada 1: `WallpaperImage.name(...)` primeiro; se `nil`, cair no `HeroImage` atual.
- Enquadramento: `scaledToFill` **centralizado** (horizontal e vertical), em vez de alinhado ao topo.
- Guardar o nome da imagem usada no `WallpaperMeta` e incluir na verificação de cache.
- Subir `layoutVersion` para 3.
- Não mudar o resto do layout (frase centralizada em 53%, faixa escura, escurecimento de 20%).

## Testes
- `available` para em buracos (1, 2, 4 → só 1 e 2).
- Mesmo dia + mesmo installID → mesmo nome; dias consecutivos → nomes diferentes com ≥ 2 imagens.
- Nenhuma imagem → `nil`.
- Cache regera quando o nome da imagem muda.

## Commit
`feat: papel de parede com fotos épicas (Wallpaper_epico_N), sorteio diário estável`
