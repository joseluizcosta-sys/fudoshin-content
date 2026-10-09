import SwiftUI
import SwiftData

private enum SettingsSheet: String, Identifiable {
    case syncGuide, mantra, race, week
    var id: String { rawValue }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var races: [Race]
    @State private var vm: SettingsViewModel?
    @State private var activeSheet: SettingsSheet?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    form(vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        Task { await vm?.save(); dismiss() }
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .syncGuide:
                    SyncGuideView()
                case .mantra:
                    MantraEditorSheet()
                case .race:
                    RaceEditView(race: races.first) {
                        await AppEnvironment.shared?.planner.refresh(now: Date(), invalidateToday: true)
                    }
                case .week:
                    WeekEditView {
                        await AppEnvironment.shared?.planner.refresh(now: Date(), invalidateToday: true)
                    }
                }
            }
        }
        .onAppear {
            if vm == nil { vm = SettingsViewModel(modelContext: ctx) }
        }
    }

    @ViewBuilder
    private func form(_ vm: SettingsViewModel) -> some View {
        Form {
            // Horários
            Section("settings.section.schedule") {
                Picker("settings.notification_hour", selection: Binding(
                    get: { vm.prefs.notificationHour },
                    set: { vm.prefs.notificationHour = $0 }
                )) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(hourLabel(h)).tag(h)
                    }
                }
            }

            // Aparência (frase no papel de parede só aparece a partir da T12)
            Section("settings.categories.section") {
                ForEach(ImageCategory.allCases, id: \.self) { cat in
                    let key = "category.\(cat.rawValue)"
                    Toggle(LocalizedStringKey(key), isOn: Binding(
                        get: { vm.prefs.categories.contains(cat) },
                        set: { on in
                            if on { vm.prefs.categories.append(cat) }
                            else  { vm.prefs.categories.removeAll { $0 == cat } }
                            if vm.prefs.categories.isEmpty { vm.prefs.categories = [cat] }
                        }
                    ))
                }
            }

            // Treino
            Section("settings.section.training") {
                HStack {
                    Text("settings.sleep_goal")
                    Spacer()
                    Stepper(
                        value: Binding(get: { vm.sleepGoalHours }, set: { vm.sleepGoalHours = $0 }),
                        in: 4...12, step: 0.5
                    ) {
                        Text(sleepLabel(vm.sleepGoalHours))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }

            // Dispositivo e sincronização
            Section {
                Button { activeSheet = .syncGuide } label: {
                    Label("settings.connect_watch",
                          systemImage: "applewatch.radiowaves.left.and.right")
                }
                .foregroundStyle(Theme.primaryText)
            }

            // Widget — instruções
            Section("settings.widget.section") {
                Text("settings.widget.lock_hint")
                    .font(.callout)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("settings.widget.standby_hint")
                    .font(.callout)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Perfil: mantra, prova, semana
            Section {
                Button("settings.mantra.label") { activeSheet = .mantra }
                    .foregroundStyle(Theme.primaryText)
                Button("settings.edit_race") { activeSheet = .race }
                    .foregroundStyle(Theme.primaryText)
                Button("settings.edit_week") { activeSheet = .week }
                    .foregroundStyle(Theme.primaryText)
            }
        }
    }

    private func sleepLabel(_ hours: Double) -> String {
        hours.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(hours)) h"
            : String(format: "%.1f h", hours)
    }

    private func hourLabel(_ h: Int) -> String {
        let date = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
