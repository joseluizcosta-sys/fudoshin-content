# Metadados da App Store (D16)

O nome no iPhone (abaixo do ícone) continua **Fudōshin**. O nome abaixo é o da página da App Store, configurado no App Store Connect por idioma.

| Campo (limite) | pt-BR | en | es |
|---|---|---|---|
| Nome (30) | Fudōshin: Mente Samurai | Fudōshin: Samurai Mindset | Fudōshin: Mente Samurái |
| Subtítulo (30) | Motivação no momento certo | Motivation at the right moment | Motivación en el momento justo |
| Palavras-chave (100, ocultas) | corrida,maratona,trail,ultra,estoicismo,frases,motivação diária,inspiração,mente forte,treino | running,marathon,trail,ultra,stoic,quotes,daily motivation,inspiration,mindset,training | correr,maratón,trail,ultra,estoicismo,frases,motivación diaria,inspiración,mentalidad,entreno |

Regras:
- Não repetir nas palavras-chave termos que já estão no nome ou subtítulo (a Apple já indexa).
- Sem nomes de terceiros (Garmin, Goggins, Kipchoge, Strava) em nome, subtítulo ou palavras-chave (DIREITOS.md, regra 2b).
- Conferir contagem de caracteres no App Store Connect antes de enviar; en/es precisam de revisão nativa.

Pendente: teste com 10 corredores (lembrança do nome e associação "fudo" em PT-BR) antes de registrar marca e domínio.

## App Store Connect — cadastro (09/10/2026)
- App: "Fudōshin: Mente Samurai" · Apple ID 6821109865 · bundle `com.atletaestoico.app` · SKU `fudoshin-ios-001` · idioma principal pt-BR.
- Grupo de assinaturas "Fudōshin Premium" (ID 22459602) — localizado pt-BR, en-US, es-MX (usa o nome do app).
- Assinatura "Premium Anual" (Apple ID 6821110604) · produto `com.atletaestoico.app.anual` · 1 ano · 175 países · base R$ 89,90
  (EUA US$ 12,99; Europa € 14,99, cálculo automático da Apple) · Compartilhamento familiar desligado.
- Oferta introdutória: grátis por 1 semana, 175 países, de 10/10/2026 sem data de término.
- Localização da assinatura: pt-BR "Frase certa para o seu treino, todo dia"; en-US "The right words for your training, daily"; es-MX "La frase justa para tu entrenamiento".
- Pendente: print da tela de assinatura (Review Information) e envio junto com a 1ª versão do app; conta Sandbox para teste no iPhone.

## Versão 1.0 — textos para colar no App Store Connect (rascunho Opus, revisar)

### Descrição pt-BR (limite 4.000)
Fudōshin é a mente que não se abala. Para quem corre, treina e compete.

Todo dia, o app escolhe a frase certa para o seu momento: depois de um treino duro, numa noite mal dormida, na véspera da prova ou no dia de descanso. Ele lê seus treinos e seu sono no app Saúde (compatível com relógios que sincronizam com o Saúde) e entrega a mensagem na hora em que ela faz diferença.

• Mensagem do dia ligada ao seu treino, sono e calendário de provas
• Widgets na tela de bloqueio e na tela inicial, em tamanho pequeno ou grande
• Papéis de parede épicos de samurai com a frase do dia, e galeria que cresce todo mês
• Automação no app Atalhos para trocar o papel de parede sozinho
• Contagem regressiva para a sua prova-alvo
• Sabedoria estoica de Sêneca, Marco Aurélio e Epicteto, com fonte conferida
• Seus dados de saúde ficam só no seu iPhone. Sem conta, sem anúncios, sem rastreamento.

Assinatura Fudōshin Premium: 7 dias grátis, depois R$ 89,90 por ano, renovação automática. Cancele quando quiser em Ajustes > Apple ID > Assinaturas, pelo menos 24 h antes do fim do período.
Termos de uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacidade: https://joseluizcosta-sys.github.io/fudoshin-content/privacidade.html

### Texto promocional pt-BR (170, editável sem nova versão)
A frase certa no momento certo: depois do treino, antes da prova, na noite mal dormida. 7 dias grátis.

### Description en (4,000)
Fudōshin: the unshakable mind. Built for runners and endurance athletes.

Every day the app picks the right words for your moment: after a hard session, after a bad night's sleep, the day before a race, or on a rest day. It reads your workouts and sleep from Apple Health (works with any watch that syncs to Health) and delivers the message when it matters.

• Daily message tied to your training, sleep and race calendar
• Lock Screen and Home Screen widgets, small or large
• Epic samurai wallpapers with today's quote, plus a gallery that grows every month
• Shortcuts automation to change your wallpaper automatically
• Countdown to your goal race
• Stoic wisdom from Seneca, Marcus Aurelius and Epictetus, source-checked
• Your health data never leaves your iPhone. No account, no ads, no tracking.

Fudōshin Premium: 7-day free trial, then an annual auto-renewing subscription. Cancel anytime in Settings > Apple ID > Subscriptions at least 24 hours before the period ends.
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy: https://joseluizcosta-sys.github.io/fudoshin-content/privacidade.html

### Descripción es (resumo — pedir revisão nativa)
Fudōshin: la mente inquebrantable. Para quien corre y entrena. Cada día, la frase justa para tu momento: después del entrenamiento, tras una mala noche, antes de la carrera. Lee tus entrenamientos y tu sueño en Salud; tus datos nunca salen del iPhone. Widgets, fondos épicos de samurái y automatización con Atajos. 7 días gratis, luego suscripción anual con renovación automática.

### App Review — Notes (em inglês, campo "Notes")
- The app reads workouts and sleep from HealthKit (read-only) only to choose which motivational message to show. Health data is processed on device and never transmitted. We do not write to HealthKit.
- The app works without Health permission (it falls back to a default daily message).
- Paywall appears after onboarding. Subscription: com.atletaestoico.app.anual, 1-week free trial. "Restore Purchases" is on the paywall.
- Network: only static GET requests to GitHub Pages (joseluizcosta-sys.github.io/fudoshin-content) for new quotes and wallpaper images. No analytics, no accounts, no third-party SDKs.
- Quotes are public-domain translations (Seneca, Marcus Aurelius, Epictetus).

### App Privacy (questionário)
- "Do you or your third-party partners collect data from this app?" → **No** → resultado "Data Not Collected".
- Base: dados de saúde não saem do aparelho; GET ao GitHub Pages não envia dados do usuário; compras são processadas pela Apple.

### Checklist da 1.0
- [ ] Versão 1.0 (project.yml já está em 1.0), build 1 → Archive no Xcode → Distribute → App Store Connect.
- [ ] Testar o build pelo TestFlight no iPhone por 3 dias (Garmin sincronizando, widget à meia-noite, automação do papel de parede, compra sandbox).
- [ ] Screenshots 6,9" (1320×2868), mínimo 3: Hoje com frase; widget na tela de bloqueio; galeria Fundo; paywall opcional.
- [ ] Categoria: Saúde e fitness (secundária: Estilo de vida). Classificação etária: 4+.
- [ ] URL de suporte (obrigatória): pode ser a página de privacidade ou uma `suporte.html` no fudoshin-content com o e-mail de contato.
- [ ] Em "Assinaturas" da versão: marcar "Premium Anual" para enviar junto + print do paywall no Review Information.

## Preenchido no App Store Connect (10/10/2026, Opus via Chrome)
- Nomes finais: pt-BR "Fudōshin: Mente Samurai" · en-US **"Fudōshin: Samurai Mind"** · es-MX **"Fudōshin: Mente de Samurái"**.
  ("Fudōshin: Samurai Mindset" e "Fudōshin: Mente Samurái" foram recusados: nome já em uso por outro app. Vigiar possível concorrente/registro.)
- Subtítulos, descrições, texto promocional, palavras-chave e URL de suporte nos 3 idiomas. Direitos autorais "2026 JC Costa".
- Categoria Saúde e fitness / Estilo de vida. Direitos de conteúdo: sim (domínio público). Não é dispositivo médico.
- Classificação etária calculada: **9+** (por "temas de saúde e bem-estar"; 12+ Vietnã, A10 Brasil).
- Privacidade: "Data Not Collected" publicada; URL de privacidade preenchida.
- Revisão: sem login; contato JC Costa / jcdev.aistudio@gmail.com / telefone (JC); notas em inglês.
- Build 1 (1.0) ligado à versão. Lançamento: **manual** após aprovação.
- Falta: screenshots 6,9"; print do paywall na assinatura e incluí-la na versão; Add for Review.
