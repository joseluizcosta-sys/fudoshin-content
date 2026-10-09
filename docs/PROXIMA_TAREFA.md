# Próxima tarefa (escrita pelo revisor Opus)

> Para o Claude Code: execute as instruções abaixo, rode todos os testes e faça um commit por bloco.
> Ao terminar, troque o status para "concluída", atualize T14 na tabela do `docs/BUILD_PLAN.md`
> e resuma em 3 linhas o que mudou. Se algo do StoreKit não se comportar como descrito, pare e explique.

**Status:** pendente
**Tarefa:** T14 — assinatura anual com 7 dias grátis e app bloqueado sem assinatura (decisão D18)

## Contexto
- Antes, compile e confira o commit b64f6bd do Opus (assinatura 不動心 FUDŌSHIN no papel de parede, sem compilar).
- D18: **um único produto**, assinatura anual auto-renovável, **R$ 89,90/ano**, oferta de entrada **gratuita de 1 semana**.
  Sem mensal, sem vitalício, sem oferta de fundador. Sem assinatura ativa (ou em teste), o app fica bloqueado.
- O BUILD_PLAN cita `com.atletaestoico.vitalicio` e grátis/pago por recurso: **ignorar**, vale a D18.

## Bloco 1 — StoreKit
- `Resources/Fudoshin.storekit` (configuração local): grupo "Fudōshin Premium", produto
  `com.atletaestoico.app.anual`, 1 ano, preço R$ 89,90 (região BR), introductory offer free trial 1 semana.
  Ligar no esquema de Run do Xcode (StoreKit Configuration). Ajustar `project.yml` se precisar.
- `Sources/Core/Store/EntitlementStore.swift` (`@MainActor`, `ObservableObject`, StoreKit 2):
  - `loadProducts()`, `purchase()`, `restore()` (`AppStore.sync()`), listener de `Transaction.updates` desde o launch.
  - Estado: `.unknown`, `.notSubscribed`, `.trial(expires: Date)`, `.active(expires: Date, willRenew: Bool)`, `.expired`.
  - Fonte da verdade: `Transaction.currentEntitlements` + `Product.SubscriptionInfo.status` (renovação e se está em oferta de entrada).
  - Gravar `isPremium` (teste ou ativa = true) em `SharedPreferences` a cada mudança, porque o widget e a ação do Atalhos leem.
  - Lógica de estado numa função pura testável: `AccessPolicy.state(from:)`.
- Commit: `feat(T14): StoreKit 2 — produto anual com teste de 7 dias e EntitlementStore`

## Bloco 2 — Paywall e bloqueio
- `RootView`: onboarding → **PaywallView** (se `!isPremium`) → `MainTabView`.
  O paywall aparece **no fim do onboarding**, depois que a pessoa viu a frase do dia (mostrar valor antes de pedir cartão).
  Ao expirar a assinatura, o app volta para o paywall.
- `Sources/Features/Paywall/PaywallView.swift`, tela cheia sem botão fechar:
  - Fundo: `Wallpaper_epico_4` escurecido; título "Mente samurai, todos os dias"; 4 benefícios curtos
    (frase certa para o seu treino · papel de parede épico diário · widget na tela de bloqueio · diário da revisão da noite).
  - Botão principal: **"Começar 7 dias grátis"**.
  - Abaixo, em texto legível (não minúsculo): **"7 dias grátis, depois \(product.displayPrice)/ano. Renova automaticamente.
    Cancele quando quiser em Ajustes › Apple ID › Assinaturas, até 24 h antes do fim do teste."**
    Usar sempre `displayPrice` do StoreKit, nunca o preço escrito no código.
  - Links "Restaurar compras", "Termos de Uso" (EULA padrão da Apple:
    https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) e "Privacidade" (URL em constante `Links.privacy`;
    por ora `https://joseluizcosta-sys.github.io/fudoshin-content/privacidade.html` — o Opus cria a página).
  - Estados: carregando produto, compra pendente (Ask to Buy), erro com "Tentar de novo", usuário cancelou (sem erro).
- Sem assinatura: o widget mostra "Abra o Fudōshin para continuar"; a ação do Atalhos devolve erro claro;
  o planner **não agenda notificações** (e cancela as pendentes).
- `MessageEngine`: remover o rebaixamento `isPremium ? trigger : .geral`. Quem usa o app é assinante ou está em teste,
  então sempre usar o gatilho real. Ajustar os testes que dependem disso.
- Ajustes: seção "Assinatura" com o estado ("Teste até 16/10" / "Ativa, renova em 09/10/2027") e o botão
  "Gerenciar assinatura" (`manageSubscriptionsSheet`).
- Commit: `feat(T14): paywall pós-onboarding, bloqueio sem assinatura e seção Assinatura em Ajustes`

## Bloco 3 — Lembrete do fim do teste
- Ao entrar em teste: notificação local **2 dias antes** do fim
  ("Seu teste do Fudōshin termina em 2 dias. Depois, \(price)/ano. Para não renovar, cancele em Ajustes › Apple ID › Assinaturas.").
  Cancelar se a pessoa cancelar ou o teste virar assinatura. Função pura para a data: `TrialReminder.fireDate(trialEnd:)`.
- DEBUG: em Debug, um seletor "Forçar acesso: automático / premium / bloqueado" para testar sem comprar.
- Commit: `feat(T14): lembrete 2 dias antes do fim do teste + seletor de acesso no Debug`

## Testes (obrigatórios)
- `AccessPolicy`: teste → premium; ativa → premium; expirada/sem compra → bloqueado.
- `TrialReminder.fireDate`: fim − 48 h; se já passou, nada.
- Planner sem assinatura não agenda notificações.
- `MessageEngine` usa o gatilho real independentemente de `isPremium`.

## Teste manual (no simulador com o .storekit)
Comprar (entra em teste), "Restaurar", expirar pelo Xcode (Debug › StoreKit › Manage Transactions) e ver o app voltar ao paywall.
