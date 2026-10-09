# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** pendente
**Tarefa:** papel de parede vira aba própria (sai de Ajustes)

## Contexto
O Opus já mudou `WallpaperComposer` (frase centralizada, `layoutVersion = 2`) no commit c65f760, **sem compilar**.
Primeiro passo: compilar e rodar os testes; corrigir o que quebrar nesse arquivo sem mudar o layout.

## 1. Nova aba "Fundo" (`Sources/Features/Wallpaper/WallpaperView.swift`)
- `MainTabView`: 4ª aba depois de Diário, `Label("tab.wallpaper", systemImage: "iphone.gen3")`, tag 3.
  String Catalog: pt "Fundo", en "Wallpaper", es "Fondo".
- Conteúdo, de cima para baixo, num `ScrollView`:
  1. **Prévia grande** do papel de parede de hoje, na proporção da tela (largura ≈ 60% da tela, cantos arredondados,
     sombra leve). Carregar com `wallpaperURL()` (gera se faltar). Enquanto carrega, `ProgressView`.
  2. Botão principal **"Salvar no Fotos"** (estilo cheio, cor `Theme.accent`), com estados salvando/salvo/erro
     (reaproveitar a lógica de `WallpaperSettingsSection.saveToPhotos`).
  3. Botão secundário **"Trocar todo dia automaticamente"** → abre o `WallpaperSetupGuide` existente com `.sheet(item:)`.
  4. Texto curto: "Ao definir, desative o zoom de perspectiva. A frase muda junto com o gatilho do dia."
- Recarregar a prévia em `.onAppear` e quando o app volta ao primeiro plano (o plano do dia pode ter mudado).
- Mover para esse arquivo o que for reaproveitável de `WallpaperSettingsSection` (lógica de salvar e status).

## 2. Ajustes
- Remover a seção "Papel de parede" e o caso `wallpaperGuide` do `SettingsSheet`. A seção "Widget" fica.

## Commit
`feat: aba Fundo com prévia grande do papel de parede; sai de Ajustes`
