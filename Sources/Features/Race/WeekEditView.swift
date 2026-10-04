import SwiftUI
import SwiftData

struct WeekEditView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var weekPlans: [WeekPlan]

    private let onSaved: () async -> Void

    @State private var model: WeekEditModel?
    @State private var saveError = false

    private let days: [(key: String, index: Int)] = [
        ("weekday.short.mon", 0), ("weekday.short.tue", 1),
        ("weekday.short.wed", 2), ("weekday.short.thu", 3),
        ("weekday.short.fri", 4), ("weekday.short.sat", 5),
        ("weekday.short.sun", 6),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    init(onSaved: @escaping () async -> Void = {}) {
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if let model {
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(days, id: \.index) { day in
                            DayChip(
                                dayKey: day.key,
                                dayIndex: day.index,
                                session: model.sessions[day.index]
                            ) {
                                model.sessions[day.index] = nextSession(model.sessions[day.index])
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.medium)
                } else {
                    ProgressView()
                }
                Spacer()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("week_edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("race_edit.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("race_edit.save") {
                        guard let m = model else { return }
                        do {
                            try m.save(into: ctx)
                            Task { await onSaved() }
                            dismiss()
                        } catch {
                            saveError = true
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("edit.save_error", isPresented: $saveError) {
                Button("OK") {}
            }
        }
        .onAppear {
            if model == nil {
                model = WeekEditModel(weekPlan: weekPlans.first)
            }
        }
    }

    private func nextSession(_ current: SessionType?) -> SessionType? {
        switch current {
        case nil:       return .leve
        case .leve:     return .forte
        case .forte:    return .longo
        case .longo:    return .descanso
        case .descanso: return nil
        }
    }
}
