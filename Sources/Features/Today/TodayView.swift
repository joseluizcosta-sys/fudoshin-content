import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var ctx
    @State private var plan: DailyPlan? = SharedStore.loadPlan()
    @State private var library: ContentLibrary? = try? ContentLibrary()
    @State private var showSettings = false
    @State private var showJournal = false
    #if DEBUG
    @State private var showDebug = false
    #endif

    private var todayEntry: DailyEntry? {
        let key = DayKey(Date()).value
        return plan?.entries.first { $0.day.value == key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    gradientHeader
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

    // MARK: - Sub-views

    private var gradientHeader: some View {
        LinearGradient(
            colors: [Color(red: 0.07, green: 0.08, blue: 0.09),
                     Color(red: 0.18, green: 0.12, blue: 0.09)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .frame(height: 220)
        .overlay(alignment: .bottomLeading) {
            if let e = todayEntry {
                Text(e.shortText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .padding(Theme.Spacing.medium)
            }
        }
    }

    @ViewBuilder
    private func entryBody(_ e: DailyEntry) -> some View {
        let msg = library?.message(withID: e.messageID)
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // Frase completa (text) ou shortText como fallback
            Text(msg?.text ?? e.shortText)
                .font(.body)
                .foregroundStyle(Theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Autor, obra, referência
            VStack(alignment: .leading, spacing: 2) {
                Text("— \(e.author)")
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

            // Revisão da noite
            Button { showJournal = true } label: {
                Text("today.journal.button")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.large)
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
