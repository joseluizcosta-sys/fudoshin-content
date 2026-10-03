# Base de Imagens — Papel de Parede Diário

## Meta inicial
| Categoria | Quantidade (MVP) | Embarcadas no app |
|---|---|---|
| trail | 40 | 10 |
| rua | 40 | 10 |
| trilha | 40 | 10 |
| **Total** | **120** (4 meses sem repetir por categoria) | **30** |

## Especificação técnica
- **Resolução:** 1290 × 2796 px (iPhone Pro Max), retrato. O app recorta para aparelhos menores.
- **Formato:** HEIC qualidade ~0,8 (≈ 0,8–1,5 MB). Guardar o original em JPEG/RAW fora do app.
- **Área segura para a frase:** terço central-inferior. Evitar elementos importantes nos 30% de cima (relógio) e nos 12% de baixo (lanterna/câmera).
- **Céu ou área "calma" no topo** ajuda o relógio a ficar legível. O efeito de profundidade do iOS funciona melhor com um elemento claro em primeiro plano (pico, árvore, ponte).

## Regras de curadoria
1. Paisagem como protagonista. **Sem pessoas identificáveis** (silhueta distante ok) e **sem marcas, números de peito ou logos**.
2. Variar horário (amanhecer, dia, entardecer, noite), estação e clima. Evitar 10 fotos parecidas seguidas.
3. Toda imagem recebe tags de humor: `calma`, `epico`, `foco`, `recomeco`. São usadas pelo motor de contexto.
4. Toda imagem precisa de `tom` (`claro` ou `escuro`) para escolher a cor da frase.
5. Nada de fotos editadas com exagero (HDR pesado, céu trocado). O público corre nesses lugares e percebe.

## De onde vêm as imagens (em ordem de preferência)
| Fonte | Custo | Direitos | Observação |
|---|---|---|---|
| **Fotos próprias** | Zero | Seus | Autenticidade é argumento de venda ("fotos de quem corre"). Revisar metadados de localização antes de publicar |
| **Fotógrafos de corrida e trail** (licença por escrito) | Por imagem ou troca por crédito no app | Contrato simples de licença não exclusiva para uso em app | Fotógrafos de provas costumam ter acervo de paisagens; o crédito no app vira divulgação para eles |
| **Imagens geradas por IA** | Baixo | Conferir os termos comerciais da ferramenta | Só como complemento. Risco de parecer "falso" para quem conhece os lugares |
| **Unsplash / Pexels** | Grátis | Zona cinzenta | A licença proíbe compilar fotos para replicar um serviço semelhante. Um app que entrega fotos como produto pode cair nisso, e a licença não cobre pessoas ou marcas na foto. **Não usar sem autorização direta do fotógrafo.** |

## Convenção de nomes
`<categoria>-<local-curto>-<nnn>.heic` → ex.: `trail-serra-fina-001.heic`, `rua-ibirapuera-004.heic`.

## Fase 2
Fotos enviadas pelos usuários, com moderação manual e licença aceita no envio. Isso vira motor de conteúdo e de comunidade.
