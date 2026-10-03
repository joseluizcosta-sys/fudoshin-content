# Landing page — como publicar e medir

Arquivo: `landing/index.html` — marca **Fudōshin** (不動心), slogan "O corpo se move. A mente, não." Ver `docs/Marca_Fudoshin.md`.

## Publicar (15 minutos, grátis)
1. Crie conta em **netlify.com** e abra **app.netlify.com/drop**.
2. Arraste a pasta `landing/` inteira. O site sai no ar com um endereço `*.netlify.app`.
3. Em **Site configuration → Forms**, ative a detecção de formulários e **publique de novo** (arraste a pasta outra vez). O formulário `lista-espera` passa a aparecer no painel.
4. Em **Forms → Notifications**, ligue o aviso por e-mail a cada inscrição. Exporte em CSV quando quiser.
5. (Opcional) Domínio próprio depois que o nome estiver decidido.

Limite do plano grátis de formulários: confira no painel da Netlify; para uma validação de 300–500 inscritos costuma bastar.

## Medir conversão
- Crie conta grátis em **goatcounter.com**, troque `SEUCODIGO` no fim do `index.html` e remova o comentário `<!-- -->` em volta do script.
- Conversão = inscrições (Netlify Forms) ÷ visitantes únicos (GoatCounter).

## Links por canal (para saber qual grupo converte)
Use um `utm_source` diferente para cada grupo. O formulário grava isso no campo `origem`.

| Canal | Link |
|---|---|
| Grupo de WhatsApp da assessoria | `https://SEUSITE.netlify.app/?utm_source=whats_assessoria` |
| Clube do Strava | `...?utm_source=strava_clube` |
| Instagram (bio/stories) | `...?utm_source=instagram` |
| LinkedIn | `...?utm_source=linkedin` |

## Gate 1 (14 dias)
- Seguir: ≥ 300 inscritos **ou** ≥ 5% de conversão.
- Sinal extra: % que escolheu "R$ 50 a R$ 100" ou "Mais de R$ 100" (≥ 30% é bom sinal de disposição a pagar).
- Não bateu: trocar a promessa do título uma vez e rodar mais 7 dias. Falhou de novo: arquivar.

## Antes de publicar
- [ ] Teste do som com 10 corredores brasileiros e checagem de marca (ver `docs/Marca_Fudoshin.md`).
- [ ] Ideogramas da página conferidos por um falante de japonês.
- [ ] Revisar a frase do rodapé ("Feito por um corredor de trail...") com a sua história real.
- [x] Condição de fundador: **50% no 1º ano do plano anual** (decidido em 03/10/2026). Configurar como oferta introdutória no StoreKit (T14) e enviar código/link aos inscritos no lançamento.
