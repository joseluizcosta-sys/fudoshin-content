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

## Arte gerada por IA (registro de procedência)
| Arquivo | Ferramenta / plano | Data | Autor do prompt | Uso |
|---|---|---|---|---|
| `Resources/Assets.xcassets/HeroSamurai.imageset/HeroSamurai.png` (original em `Design/Arte/`) | Google Gemini, plano pago | 07/10/2026 | JC | Topo da tela Hoje (v2, com linhas de velocidade; v1 guardada em `Design/Arte/HeroSamurai_original.png`) |

Notas: imagem gerada por IA não tem proteção de direito autoral garantida (terceiros podem copiar). Guardar o prompt usado. Resolução atual 1024×572 — gerar de novo em resolução maior (mín. 2048 px de altura, formato retrato) antes do lançamento. Evitar logos de marcas nos tênis.
| `HeroSamurai.jpg` v3 (retrato 1536×2752, original em `Design/Arte/HeroSamurai_v3_retrato_1536x2752_original.jpeg`) | Google Gemini, plano pago | 08/10/2026 | JC | Topo da tela Hoje (atual) |

✅ **Resolvido em 07/10/2026** (HeroSamurai substituída pela Hero_geral sem logo). Histórico: o tênis do pé direito tem as listras cruzadas da **ASICS** (marca registrada). Gerar de novo com "tênis genéricos, sem logotipo e sem listras laterais" antes de usar em App Store, landing ou anúncios. Na tela Hoje o tênis fica quase todo sob o degradê; aceitável só no beta.

---

## Imagens hero por momento do treino (gatilho)

A tela Hoje troca a imagem de topo conforme o gatilho do dia. O nome do asset segue:

```
Hero_<trigger.rawValue>
```

Se o asset não existir, o app usa `HeroSamurai` como fallback (comportamento definido em `Core/Messages/HeroImage.swift`).

| Asset                | Gatilho (`Trigger`)   | Momento                          |
|---------------------|-----------------------|----------------------------------|
| `Hero_pos_treino`   | `.posTreino`          | Após treino intenso              |
| `Hero_vespera_chave`| `.vesperaChave`       | Véspera de sessão chave          |
| `Hero_descanso`     | `.descanso`           | Dia de descanso                  |
| `Hero_sono_ruim`    | `.sonoRuim`           | Noite ruim de sono               |
| `Hero_retorno`      | `.retorno`            | Retorno após pausa               |
| `Hero_marco_prova`  | `.marcoProva`         | Marco perto da prova             |
| `Hero_geral`        | `.geral`              | Contexto geral (padrão)          |

**Especificações:** vertical 9:16 · ~1536 × 2752 px · JPEG.
Adicione os assets gradualmente em `Resources/Assets.xcassets`; o app usa `HeroSamurai` enquanto não existirem.

### Hero por gatilho — instaladas em 07/10/2026
Geradas no Gemini (plano pago) por JC com os prompts de `docs/Prompts_Hero_Gemini.md`. Originais 1536×2752 em `Design/Arte/Hero_<gatilho>.jpeg`; no app em 1290×2311, JPEG q82 (~370–600 KB cada). Ideogramas e degradês são aplicados pelo código (`TodayHeroView`), não na imagem.

| Asset | Revisão |
|---|---|
| Hero_vespera_chave | ok — tênis sem logo, mãos ok |
| Hero_pos_treino | ok |
| Hero_descanso | ok |
| Hero_sono_ruim | ok |
| Hero_retorno | ok — portal é um torii (o prompt pedia portão de madeira); ideograma 動 perde contraste no fundo claro |
| Hero_marco_prova | ok |
| Hero_geral | ok — regerada sem ASICS (07/10/2026). Instalada como `HeroSamurai` (fallback que cobre o gatilho geral), sem imageset duplicado |
