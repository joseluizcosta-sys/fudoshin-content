import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var ctx
    @State private var plan: DailyPlan? = SharedStore.loadPlan()
    @State private var library: ContentLibrary? = try? ContentLibrary()
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
                    imageHeader
                    if let e = todayEntry {
                        entryBody(e)
                    } else {
                        Text("today.no_plan")
                            .font(.body)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(Theme.Spacing.large)
                    }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("today.title")
            .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Cabeçalho (reservado para imagem em T12; por ora gradiente + 不動心)

    private var imageHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.09),
                         Color(red: 0.10, green: 0.09, blue: 0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text("不動心")
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(Color.white.opacity(0.08))
                .allowsHitTesting(false)
        }
        .frame(height: 220)
    }

    // MARK: - Corpo

    @ViewBuilder
    private func entryBody(_ e: DailyEntry) -> some View {
        let msg = library?.message(withID: e.messageID)
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {

            // Etiqueta de contexto (acima da frase)
            Text(contextLabel(e))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)

            // Frase completa uma única vez
            Text(msg?.text ?? e.shortText)
                .font(.body)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Autor + obra + referência
            VStack(alignment: .leading, spacing: 2) {
                Text(attributionText(author: e.author, isParaphrase: e.isParaphrase))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.primaryText)
                if let work = msg?.work, let ref = msg?.reference, !work.isEmpty {
                    Text("\(work) · \(ref)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Divider()

            // Reflexão
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

            // Botão de revisão (estado conforme JournalEntry de hoje)
            journalButton
        }
        .padding(Theme.Spacing.large)
    }

    // MARK: - Botão de revisão

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

    // MARK: - Helpers

    private func contextLabel(_ e: DailyEntry) -> String {
        guard e.trigger != .geral, !e.inlineText.isEmpty else {
            return String(localized: "today.context.geral")
        }
        return e.inlineText
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
        }
        #if DEBUG
        ToolbarItem(placement: .topBarLeading) {
            Button { showDebug = true } label: {
                Image(systemName: "stethoscope")
            }
        }
        #endif
    }
}
