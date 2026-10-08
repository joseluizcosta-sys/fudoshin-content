# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça o commit pedido.
> Ao terminar, troque o status para "concluída" e resuma em 3 linhas o que mudou.

**Status:** concluída
**Tarefa:** pós-treino não dispara em dia de sono ruim (bug real em 08/10/2026)

## O que aconteceu
Treino terminou às 7:09 (aparece no Debug com horário e distância). Today's Log: `fd_derrotas`, gatilho `sono_ruim`.
O refresh das ~6h gravou `sono_ruim` no DeliveryLog. Como `sono_ruim` é evento "sticky" (`DailyPlanner.eventTriggers`),
`resolveToday` só reidratou a entrada e o pós-treino nunca a substituiu. Nem a mensagem nem a notificação de pós-treino saíram.

## 1. Pós-treino supera outro gatilho de evento (DailyPlanner.swift)
Em `resolveToday`, no ramo `if Self.eventTriggers.contains(log.trigger)`:
- Calcular `let fresh = TriggerEngine.trigger(for: context, now: now, calendar: calendar)`.
- Se `fresh == .posTreino && existingEntry.trigger != .posTreino` → **promover**: `makeEntry(...)` novo com `.posTreino`
  (nova mensagem do gatilho pós-treino). Senão, reidratar como hoje.
- `resolveToday` passa a devolver também se houve promoção, ex.: `(entry: DailyEntry, promoted: Bool)`.
- Em `_doRefresh`: `shouldTryImmediate = immediateNotifyTriggers.contains(todayEntry.trigger) && (!alreadyNotified || promoted)`.
  Motivo: se o dia começou com `retorno` já notificado, o pós-treino também tem que notificar.
- O `upsertDeliveryLog` já grava o novo gatilho e messageID; não mexer no "nunca resetar notified para false".

## 2. Notificação no horário de silêncio é adiada, não perdida (NotificationScheduler.swift)
Em `scheduleImmediate(entry:now:calendar:)`:
- Se `hour < quietEnd` (madrugada): agendar para hoje às `quietEnd`:00 com `UNCalendarNotificationTrigger`,
  mesmo identificador `nowPrefix + dia`, remover a diária pendente de hoje e **retornar true**.
- Se `hour >= quietStart` (noite): manter `return false`.
- Entre 7h e 21h: como está (intervalo de 1 s).

## 3. Janela do pós-treino de 3h para 6h (TriggerEngine.swift)
Criar `static let postWorkoutWindowHours: Double = 6` e usar no lugar do `3 * 3600`.
Motivo: o Garmin às vezes demora horas para mandar o treino ao app Saúde.
Atualizar o comentário do passo 2.

## Testes (obrigatórios)
- **DailyPlannerTests**:
  (a) refresh às 6:00 com sono ruim → `sono_ruim`; refresh às 8:00 com treino terminado 7:09 → `pos_treino`,
      messageID muda, `scheduleImmediate` chamado 1 vez; novo refresh às 9:00 → continua `pos_treino`, sem 2ª imediata.
  (b) dia começou `retorno` com `notified = true`; chega treino → `pos_treino` e `scheduleImmediate` chamado.
  (c) `sono_ruim` sem treino novo continua sticky (regressão).
- **NotificationSchedulerTests**: 5:30 → retorna true, request com gatilho de calendário às 7:00;
  22:00 → false e nenhum request; 10:00 → gatilho de intervalo.
- **TriggerEngineTests**: treino terminado há 5h → `pos_treino`; há 7h → não.

## Commit
`fix: pós-treino supera sono ruim/retorno; notificação da madrugada adiada para 7h; janela de 6h`
