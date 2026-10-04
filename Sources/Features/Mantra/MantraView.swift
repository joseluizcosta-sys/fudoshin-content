import SwiftUI
import SwiftData

struct MantraView: View {
    @Query private var profiles: [AthleteProfile]
    @Environment(\.modelContext) private var ctx
    @State private var editing = false
    @State private var editText = ""
    @State private var copied = false

    private var profile: AthleteProfile? { profiles.first }
    private var mantra: String { profile?.mantra ?? "" }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.large) {
                Spacer()

                if editing {
                    TextField("mantra.placeholder", text: $editText, axis: .vertical)
                        .font(.title2.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.primaryText)
                        .padding(Theme.Spacing.large)
                        .lineLimit(4...8)
                } else if mantra.isEmpty {
                    Text("mantra.empty")
                        .font(.body)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(Theme.Spacing.large)
                } else {
                    Text(mantra)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(Theme.Spacing.large)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: Theme.Spacing.medium) {
                    if !editing && !mantra.isEmpty {
                        Button {
                            UIPasteboard.general.string = mantra
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        } label: {
                            Label(copied ? "mantra.copied" : "mantra.copy",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.accent)
                    }

                    if editing {
                        Button("mantra.done") { commitEdit() }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                    } else {
                        Button("mantra.edit") {
                            editText = mantra
                            editing = true
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.accent)
                    }
                }
                .padding(.bottom, Theme.Spacing.large)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("mantra.title")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func commitEdit() {
        profile?.mantra = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        try? ctx.save()
        editing = false
    }
}
