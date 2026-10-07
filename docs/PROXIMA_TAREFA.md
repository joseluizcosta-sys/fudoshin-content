# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** pendente
**Tarefa:** imagem do samurai no topo da tela Hoje (o ícone já está instalado)

Referência visual: `Design/Arte/Mockup_Hoje_v3.png`.
Atenção: as linhas de velocidade passam atrás do 不動心 — reforçar a faixa escura à esquerda e a sombra do texto para manter a leitura.

### Topo da tela Hoje
A imagem `HeroSamurai` (no Assets.xcassets) agora é **retrato** (572×1024).
1. Em `TodayView`, criar `TodayHeroView` no topo, ocupando ~60% da altura da tela, ignorando a safe area de cima:
   - `Image("HeroSamurai").resizable().scaledToFill()` alinhada pelo **topo** (`alignment: .top`), largura total, cortando só embaixo.
   - Degradê na parte de baixo, do transparente para `Theme.background` (últimos ~40% da imagem),
     e um degradê suave escuro no topo para a barra de status ficar legível.
   - Faixa escura sutil na lateral esquerda e, por cima, **不動心 na vertical** (um ideograma por linha),
     fonte serif bold ~44 pt; 不 e 心 em cor clara, **動 em `Theme.accent`**. Sombra leve para contraste.
     O texto 不動心 é decorativo: `.accessibilityLabel("Fudōshin")`.
2. Logo abaixo, sobreposto ao fim do degradê: contexto do dia (accent), frase do dia (serif, grande), autor ("— autor" ou "Inspirado em…").
   Cards de reflexão e prova continuam como estão.
3. Modo claro: o degradê vai para o `Theme.background` claro, mas a frase sobre a imagem
   precisa de contraste — usar um degradê mais longo ou um fundo translúcido sob o texto. Conferir nos dois modos.
4. Acessibilidade: com Dynamic Type grande, a frase não pode ficar cortada (o topo diminui antes).
   A imagem é decorativa (`.accessibilityHidden(true)`).
5. Rodar todos os testes; conferir no iPhone (claro, escuro, fonte grande).
6. Commit (`git add -A`, depois `git status` limpo):
   `feat: imagem do samurai no topo da tela Hoje`
