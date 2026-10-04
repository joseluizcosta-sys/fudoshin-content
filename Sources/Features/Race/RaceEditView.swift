import SwiftUI
import SwiftData

struct RaceEditView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    private let existingRace: Race?
    private let onSaved: () async -> Void

    @State private var model: RaceEditModel?
    @State private var showRemoveConfirm = false

    init(race: Race? = nil, onSaved: @escaping () async -> Void = {}) {
        self.existingRace = race
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    form(model)
                } else {
                    ProgressView()
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(existingRace != nil
                ? LocalizedStringKey("race_edit.title.edit")
                : LocalizedStringKey("race_edit.title.create"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("race_edit.cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("race_edit.save") {
                        guard let m = model else { return }
                        try? m.save(into: ctx)
                        Task { await onSaved() }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!(model?.isValid ?? false))
                }
            }
        }
        .onAppear {
            if model == nil {
                model = RaceEditModel(mode: existingRace.map { .edit($0) } ?? .create)
            }
        }
    }

    @ViewBuilder
    private func form(_ model: RaceEditModel) -> some View {
        Form {
            Section {
                LabeledContent(String(localized: "onboarding.race.name.label")) {
                    TextField("onboarding.race.name.placeholder", text: Binding(
                        get: { model.name },
                        set: { model.name = $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                }

                DatePicker(
                    String(localized: "onboarding.race.date.label"),
                    selection: Binding(get: { model.date }, set: { model.date = $0 }),
                    in: Date.now...,
                    displayedComponents: .date
                )

                LabeledContent(String(localized: "onboarding.race.distance.label")) {
                    TextField(
                        "",
                        value: Binding(get: { model.distanceKm }, set: { model.distanceKm = $0 }),
                        format: .number.precision(.fractionLength(0...1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }

                Picker(
                    String(localized: "onboarding.race.category.label"),
                    selection: Binding(get: { model.category }, set: { model.category = $0 })
                ) {
                    ForEach(ImageCategory.allCases, id: \.self) { cat in
                        let key = "category.\(cat.rawValue)"
                        Text(LocalizedStringKey(key)).tag(cat)
                    }
                }
            }

            if model.isEditMode {
                Section {
                    Button(role: .destructive) {
                        showRemoveConfirm = true
                    } label: {
                        Text("race_edit.remove")
                    }
                }
            }
        }
        .confirmationDialog(
            "race_edit.remove.confirm.title",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("race_edit.remove.confirm.action", role: .destructive) {
                try? model.remove(from: ctx)
                Task { await onSaved() }
                dismiss()
            }
            Button("race_edit.cancel", role: .cancel) {}
        } message: {
            Text("race_edit.remove.confirm.message")
        }
    }
}
