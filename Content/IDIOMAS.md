# Idiomas — conteúdo e interface

## Escopo
| Fase | Idiomas |
|---|---|
| Lançamento | Português (pt-BR), Inglês (en), Espanhol (es) |
| Expansão (sem mudar código) | Alemão (de), Francês (fr), Italiano (it), Chinês simplificado (zh-Hans) |

## Decisão: frases armazenadas por idioma, traduzidas na produção do conteúdo
A tradução é feita **uma vez, por nós, antes de publicar** (IA para o rascunho + revisão nativa). O app não traduz nada em tempo real.

| Opção | Funciona? | Problema |
|---|---|---|
| **Armazenar por idioma** (escolhida) | Sim | Custo de revisão por idioma |
| Tradução no aparelho (Apple Translation) | Parcial | Usuário precisa baixar o idioma; não roda dentro do widget; não respeita o limite de 70/25 caracteres; pode distorcer a citação |
| IA do aparelho (Foundation Models) | Parcial | Só iPhone 15 Pro+ com iOS 26; o widget não consegue chamar; mesmo risco de distorcer citação |
| API de tradução na nuvem (DeepL, Google) | Sim | Quebra a regra de zero servidor, tem custo recorrente e depende de internet |

**Onde a IA entra em tempo real:** só na *reflexão personalizada* (Foundation Models responde no idioma do usuário). A citação nunca é gerada nem traduzida no aparelho.

## Estrutura dos arquivos
```
Content/messages/
├── base.json     # IDs, autor, obra, referência, gatilhos, nomes de autores/obras por idioma
├── pt-BR.json    # texto, texto_curto, texto_inline, reflexao + perguntas do diário + textos de contexto
├── en.json
└── es.json       # novo idioma = novo arquivo com os mesmos IDs
```
**Fallback:** idioma do usuário → `en` → `pt-BR`. Mensagem sem tradução revisada não aparece naquele idioma (cai no fallback só se o idioma inteiro não existir).

## Limites de texto por idioma (widget da tela de bloqueio)
| Idioma | texto_curto | texto_inline |
|---|---|---|
| pt-BR, en, es, fr, it, de | ≤ 70 | ≤ 25 |
| zh-Hans | ≤ 32 | ≤ 12 |

Alemão tende a ficar mais longo: escrever a versão curta pensando no limite, não traduzir literalmente.

## Fluxo para cada idioma novo
1. Copiar `en.json` → `<idioma>.json`.
2. **Rascunho com IA** (Sonnet): traduzir a partir do texto em domínio público (não do português), mantendo o sentido; gerar versões curta e inline dentro do limite.
3. **Revisão nativa** (corredor que fala o idioma, se possível): 2–4 horas para 120 mensagens. Marcar `revisao.status = "revisado"`.
4. Validar com o teste automático (IDs completos, limites).
5. Traduzir a interface (String Catalog no Xcode) e a página da App Store do país.

## Interface (UI)
- Todos os textos da interface no **String Catalog** (`Localizable.xcstrings`) desde a T00, inclusive no widget.
- O idioma segue o do iPhone. O iOS já oferece a troca por app em Ajustes → AtletaEstoico → Idioma; não é preciso seletor próprio.
- Datas, números e distâncias com formatadores do sistema (`Date.FormatStyle`, `Measurement`), nunca texto fixo. Em inglês dos EUA, distância em milhas.

## Custo estimado por idioma (a validar)
- Rascunho por IA: baixo.
- Revisão nativa de 120 mensagens + interface: 4–8 horas de um revisor.
- Página da App Store + screenshots localizados: 2–3 horas.
