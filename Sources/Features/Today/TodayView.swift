import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var ctx
    @State private var plan: DailyPlan? = SharedStore.loadPlan()
    @State private var library: ContentLibrary? = ContentLibrary.current()
    @State private var showSettings = false
    @State private var showJournal = false
    @Query(sort: \JournalEntry.dayValue) private var journalEntries: [JournalEntry]
    #if DEBUG
    @State private var showDebug = false
    #endif

    private var todayEntry: DailyEntry? {
        let key = DayKey(Date()).value
        return plan?.entries.first { $0.day.value == key }
    }

    private var hasTodayJournal: Bool {
        let key = DayKey(Date()).value
        return journalEntries.contains { $0.dayValue == key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Imagem hero — ignora safe area de cima
                    TodayHeroView()

                    // Frase do dia — logo abaixo, sobreposta ao fim do degradê
                    if let e = todayEntry {
                        quoteSection(e)
                    } else {
                        Text("today.no_plan")
                            .font(.body)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(Theme.Spacing.large)
                    }

                    SyncHintBanner()

                    if let e = todayEntry {
                        reflectionBody(e)
                    }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showJournal) { JournalEntrySheet(day: DayKey(Date())) }
            #if DEBUG
            .sheet(isPresented: $showDebug) { HealthDebugView() }
            #endif
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)
            ) { _ in
                plan = SharedStore.loadPlan()
            }
        }
    }

    // MARK: - Frase do dia (fora da imagem, sobre Theme.background)

    @ViewBuilder
    private func quoteSection(_ e: DailyEntry) -> some View {
        let msg = library?.message(withID: e.messageID)
        let quoteText = msg?.text ?? e.shortText
        let ctxLabel = contextLabel(e)

        VStack(alignment: .leading, spacing: 8) {
            if !ctxLabel.isEmpty {
                Text(ctxLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
            }

            Text(quoteText)
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(attributionText(author: e.author, isParaphrase: e.isParaphrase))
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)

            if let work = msg?.work, !work.isEmpty {
                Text("\(work) · \(msg?.reference ?? "")")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.top, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.large)
    }

    private func contextLabel(_ e: DailyEntry) -> String {
        guard e.trigger != .geral, !e.inlineText.isEmpty else {
            return String(localized: "today.context.geral")
        }
        return e.inlineText
    }

    // MARK: - Reflexão (card abaixo da frase)

    @ViewBuilder
    private func reflectionBody(_ e: DailyEntry) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Divider()
            if !e.reflection.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("today.reflection.section")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .textCase(.uppercase)
                    Text(e.reflection)
                        .font(.callout)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            journalButton
        }
        .padding(Theme.Spacing.large)
    }

    // MARK: - Botão do diário

    private var journalButton: some View {
        Button { showJournal = true } label: {
            if hasTodayJournal {
                Label("today.journal.done", systemImage: "checkmark")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.secondaryText.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.primaryText)
            } else {
                Text("today.journal.button")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
        }
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            Button { showDebug = true } label: {
                Image(systemName: "stethoscope")
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
        }
        #endif
    }
}

// MARK: - TodayHeroView

private struct TodayHeroView: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    private var heroHeight: CGFloat {
        let screen = UIScreen.main.bounds.height
        // Com Dynamic Type grande o hero encolhe para dar espaço ao texto abaixo
        if typeSize >= .xLarge { return max(screen * 0.44, 300) }
        return screen * 0.58
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Imagem retrato: alinhada pelo TOPO — cabeça, sol e tronco visíveis; pés cortados
            Image("HeroSamurai")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, alignment: .top)
                .accessibilityHidden(true)

            // Degradê topo (~120 pt) — barra de status e botões da toolbar legíveis
            LinearGradient(
                colors: [Color.black.opacity(0.35), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 120)

            // Faixa escura esquerda — contraste para 不動心
            HStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.40), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 88)
                Spacer()
            }

            // Degradê inferior (últimos ~40%) — transparente → Theme.background
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Theme.background],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: heroHeight * 0.40)
            }

            // 不動心 vertical — um ideograma por linha, lateral esquerda
            // 不 e 心 claros; 動 em Theme.accent; sombra para contraste
            HStack(alignment: .top) {
                VStack(spacing: 2) {
                    Text("不").foregroundStyle(Color.white.opacity(0.92))
                    Text("動").foregroundStyle(Theme.accent)
                    Text("心").foregroundStyle(Color.white.opacity(0.92))
                }
                .font(.system(size: 44, weight: .bold, design: .serif))
                .shadow(color: .black.opacity(0.65), radius: 4, x: 1, y: 2)
                .accessibilityLabel("Fudōshin")
                .padding(.leading, 20)
                .padding(.top, heroHeight * 0.22)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
        // Estende a imagem por trás da barra de status e da barra de navegação
        .ignoresSafeArea(.all, edges: .top)
    }
}
