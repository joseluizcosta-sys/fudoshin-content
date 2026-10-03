import SwiftUI

struct WeekStep: View {
    @Bindable var state: OnboardingState

    private let days: [(key: String, index: Int)] = [
        ("weekday.short.mon", 0), ("weekday.short.tue", 1),
        ("weekday.short.wed", 2), ("weekday.short.thu", 3),
        ("weekday.short.fri", 4), ("weekday.short.sat", 5),
        ("weekday.short.sun", 6),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("onboarding.week.title")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text("onboarding.week.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(days, id: \.index) { day in
                        DayChip(
                            dayKey: day.key,
                            session: state.weekSessions[day.index]
                        ) {
                            state.weekSessions[day.index] = nextSession(state.weekSessions[day.index])
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
            }
            .padding(.vertical, Theme.Spacing.medium)

            Spacer()

            Button {
                withAnimation { state.step += 1 }
            } label: {
                Text("onboarding.button.next").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .padding(Theme.Spacing.large)
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

// MARK: - Day chip

private struct DayChip: View {
    let dayKey: String
    let session: SessionType?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(LocalizedStringKey(dayKey))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.secondaryText)
                Text(sessionLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(labelColor)
            }
            .frame(width: 52, height: 60)
            .background(chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var sessionLabel: String {
        guard let s = session else { return "–" }
        switch s {
        case .leve:     return String(localized: "session.leve")
        case .forte:    return String(localized: "session.forte")
        case .longo:    return String(localized: "session.longo")
        case .descanso: return String(localized: "session.descanso")
        }
    }

    private var labelColor: Color {
        session == nil ? Theme.secondaryText : Theme.accent
    }

    private var chipBackground: Color {
        session == nil
            ? Theme.secondaryText.opacity(0.08)
            : Theme.accent.opacity(0.12)
    }
}
