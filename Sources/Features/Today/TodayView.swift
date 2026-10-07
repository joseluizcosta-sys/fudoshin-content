import SwiftUI
import SwiftData

private enum TodaySheet: String, Identifiable {
    case settings, journal, debug
    var id: String { rawValue }
}

struct TodayView: View {
    @Environment(\.modelContext) private var ctx
    @State private var plan: DailyPlan? = SharedStore.loadPlan()
    @State private var library: ContentLibrary? = ContentLibrary.current()
    @State private var activeSheet: TodaySheet?
    @Query(sort: \JournalEntry.dayValue) private var journalEntries: [JournalEntry]
    @Query private var profiles: [AthleteProfile]

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
                    // 1. Imagem hero
                    TodayHeroView(trigger: todayEntry?.trigger)

                    if let e = todayEntry {
                        // 2. Frase + 3. Reflexão (mesmo bloco, sem Divider)
                        quoteSection(e)

                        // 4. Botão "Revisão da noite"
                        journalButton
                            .padding(.horizontal, Theme.Spacing.large)
                            .padding(.bottom, Theme.Spacing.large)
                    } else {
                        Text("today.no_plan")
                            .font(.body)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(Theme.Spacing.large)
                    }

                    // 5. SyncHintBanner
                    SyncHintBanner()

                    // 6. Mantra no fim
                    if let mantra = profiles.first?.mantra, !mantra.isEmpty {
                        mantraSection(mantra)
                    }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarItems }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView()
                case .journal:
                    JournalEntrySheet(day: DayKey(Date()))
                case .debug:
                    #if DEBUG
                    HealthDebugView()
                    #else
                    EmptyView()
                    #endif
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)
            ) { _ in
                plan = SharedStore.loadPlan()
            }
        }
    }

    // MARK: - Frase + Reflexão (bloco único, sem Divider)

    @ViewBuilder
    private func quoteSection(_ e: DailyEntry) -> some View {
        let msg = library?.message(withID: e.messageID)
        let quoteText = msg?.text ?? e.shortText
        let ctxLabel = contextLabel(e)

        VStack(alignment: .leading, spacing: 8) {
            // Contexto → frase → autor → obra · ref
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

            // Reflexão logo abaixo (~12 pt = spacing(8) + padding(.top, 4))
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
                .padding(.top, 4)
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

    // MARK: - Mantra (fim da tela)

    @ViewBuilder
    private func mantraSection(_ mantra: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            Text(mantra)
                .font(.callout)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(2)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.large)
    }

    // MARK: - Botão do diário

    private var journalButton: some View {
        Button { activeSheet = .journal } label: {
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
            Button { activeSheet = .settings } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
        }
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            Button { activeSheet = .debug } label: {
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
    let trigger: Trigger?
    @Environment(\.dynamicTypeSize) private var typeSize

    private var heroHeight: CGFloat {
        let screen = UIScreen.main.bounds.height
        if typeSize >= .xLarge { return max(screen * 0.44, 300) }
        return screen * 0.58
    }

    var body: some View {
        let imageName = trigger.map { HeroImage.name(for: $0) { UIImage(named: $0) != nil } }
                        ?? HeroImage.fallback
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight, alignment: .top)
            .clipped()
            .accessibilityHidden(true)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(0.35), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 120)
            }
            .overlay(alignment: .leading) {
                LinearGradient(
                    colors: [Color.black.opacity(0.40), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 88)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Theme.background],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: heroHeight * 0.40)
            }
            .overlay(alignment: .topLeading) {
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
            }
            .ignoresSafeArea(.all, edges: .top)
    }
}
