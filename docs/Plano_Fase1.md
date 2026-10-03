# Plano de Execução — Fase 1

**Início:** 28/09/2026 · **Duração-alvo:** 8 semanas até o TestFlight público

---

## Semana 0–1 · Verificações e validação (antes de codar)

- [ ] **Teste de 10 minutos no seu iPhone:** criar no app Atalhos uma automação diária com "Definir papel de parede" usando uma foto da galeria. Confirmar que roda sem pedir confirmação na sua versão do iOS.

- [ ] **Checar os dados do Garmin no app Saúde:** Garmin Connect → Configurações → Apps conectados → Saúde. Anotar quais dados chegam (treinos, FC, sono?) e com quanto atraso.
- [ ] **Nome e marca:** listar 5 nomes, checar App Store, INPI e domínio. Evitar "Daily Stoic" e "Stoa".
- [ ] **Landing page** com a promessa, 3 benefícios, print mockado e lista de espera. Medir conversão.
- [ ] **Divulgação:** 3–4 grupos de corrida e trail, clubes do Strava, 2 assessorias esportivas.
- [ ] **10 entrevistas curtas** com corredores: quando precisam de cabeça no lugar? Quando largam apps de frases?

**Gate 1:** ≥ 300 inscritos ou ≥ 5% de conversão. Se não bater, ajustar a promessa uma vez; se falhar de novo, arquivar.

## Semana 2 · Conteúdo

- [ ] Curar **120 mensagens** em pt-BR, en e es (`Content/messages/`), cada uma com `texto_curto` (≤ 70) e `texto_inline` (≤ 25) para o widget, (domínio público + paráfrases próprias), marcadas por gatilho (ver `Content/quotes_seed.json`).
- [ ] Escrever as trilhas de prova (T-30, T-7, T-1, D0) e as 20 perguntas do diário.
- [ ] **Imagens:** reunir 30 fotos para embarcar (10 por categoria) e mapear a fonte das outras 90 (fotos próprias, fotógrafos). Catalogar cada uma em `Content/images_seed.json`.
- [ ] Conseguir **2 revisores nativos** (inglês e espanhol), de preferência corredores. Ver `Content/IDIOMAS.md`.
- [ ] Revisar tudo contra `Content/DIREITOS.md`.

## Semana 3–5 · Build do MVP

| Ordem | Módulo | Pronto quando |
|---|---|---|
| 1 | Data (SwiftData) + Onboarding | Prova, semana e "porquê" salvos |
| 2 | HealthKitService | Lê corridas e sono dos últimos 14 dias |
| 3 | TriggerEngine + testes unitários | Cada gatilho da matriz coberto por teste |
| 4 | MessageEngine (biblioteca) | Nunca repete mensagem em 30 dias |
| 5 | Notificações | Máx. 1/dia, respeita horário |
| 6 | Today + Race + Mantra + Journal | Fluxo completo navegável |
| 7 | Wallpaper: sorteio + composição foto/frase | Mesma imagem no app, widget e Atalhos; sem repetir em 60 dias |
| 8 | Ação de Atalhos + guia de automação | Automação diária troca o papel de parede sem abrir o app |
| 9 | Widget da tela de bloqueio | Retangular, inline e circular; troca diária sem abrir o app; mesma mensagem da notificação |
| 9b | Widget da tela inicial | Paisagem do dia + frase + dias para a prova |
| 10 | Foundation Models (iOS 26+) | Personaliza com o "porquê"; fallback para a biblioteca |

## Semana 6 · Monetização e privacidade

- [ ] StoreKit 2 (anual + compra única para teste A/B).
- [ ] Política de privacidade (dado de saúde fica no aparelho; nada coletado).
- [ ] App Privacy na App Store Connect: "Dados não coletados".

## Semana 7–8 · Beta

- [ ] TestFlight com 30–50 pessoas da lista de espera.
- [ ] Medir D7, notificações abertas, revisões noturnas feitas e **% que configurou a automação do papel de parede** e **% com widget na tela de bloqueio**.

**Gate 2:** D7 ≥ 35%. Se não bater, o problema está no gatilho ou no conteúdo, não em features novas.

---

## O que não fazer nesta fase

- Integração com a Garmin API, Apple Watch ou backend.
- Gastar com anúncios antes de provar retenção.
- Construir em paralelo com o ScanlyPDF sem decidir a prioridade.
