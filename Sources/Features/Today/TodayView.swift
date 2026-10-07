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
                    TodayHeroView(
                        entry: todayEntry,
                        quoteText: todayEntry.map {
                            library?.message(withID: $0.messageID)?.text ?? $0.shortText
                        } ?? "",
                        contextLabel: todayEntry.map { heroContextLabel($0) } ?? ""
                    )
                    SyncHintBanner()
                    if let e = todayEntry {
                        reflectionBody(e)
                    } else {
                        Text("today.no_plan")
                            .font(.body)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(Theme.Spacing.large)
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

    // MARK: - Helpers

    private func heroContextLabel(_ e: DailyEntry) -> String {
        guard e.trigger != .geral, !e.inlineText.isEmpty else {
            return String(localized: "today.context.geral")
        }
        return e.inlineText
    }

    // MARK: - Reflection section (below hero)

    @ViewBuilder
    private func reflectionBody(_ e: DailyEntry) -> some View {
        let msg = library?.message(withID: e.messageID)
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
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
            if let work = msg?.work, let ref = msg?.reference, !work.isEmpty {
                Text("\(work) · \(ref)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            journalButton
        }
        .padding(Theme.Spacing.large)
    }

    // MARK: - Journal button

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
    let entry: DailyEntry?
    let quoteText: String
    let contextLabel: String

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme

    private var heroHeight: CGFloat {
        let screen = UIScreen.main.bounds.height
        if typeSize >= .xLarge { return max(screen * 0.45, 320) }
        return screen * 0.60
    }

    private var bottomGradientFraction: CGFloat {
        colorScheme == .light ? 0.55 : 0.42
    }

    var body: some View {
        ZStack {
            // Hero image: retrato, alinhado pelo topo, cortando embaixo
            Image("HeroSamurai")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            // Degradê topo — barra de status e barra de navegação legíveis
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.55), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: heroHeight * 0.28)
                Spacer()
            }

            // Faixa escura esquerda — contraste para 不動心
            HStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.45), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 88)
                Spacer()
            }

            // Degradê inferior — transparente → Theme.background
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Theme.background],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: heroHeight * bottomGradientFraction)
            }

            // 不動心 vertical — um ideograma por linha, lateral esquerda
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
                .padding(.top, heroHeight * 0.20)
                Spacer()
            }

            // Texto do dia — contexto, frase, autor — sobreposto ao degradê inferior
            VStack {
                Spacer()
                if let e = entry {
                    quoteOverlay(e)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
        .ignoresSafeArea(.container, edges: .top)
    }

    @ViewBuilder
    private func quoteOverlay(_ e: DailyEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !contextLabel.isEmpty {
                Text(contextLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
            }

            Text(quoteText)
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1)

            Text(attributionText(author: e.author, isParaphrase: e.isParaphrase))
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.bottom, Theme.Spacing.large)
        // Fundo translúcido extra no modo claro para garantir contraste
        .background(
            colorScheme == .light
                ? LinearGradient(
                    colors: [.clear, Color.black.opacity(0.28)],
                    startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        )
    }
}
