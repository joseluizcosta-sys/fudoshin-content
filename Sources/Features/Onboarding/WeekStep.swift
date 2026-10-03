import SwiftUI

struct WeekStep: View {
    @Bindable var state: OnboardingState

    private let days: [(key: String, index: Int)] = [
        ("weekday.short.mon", 0), ("weekday.short.tue", 1),
        ("weekday.short.wed", 2), ("weekday.short.thu", 3),
        ("weekday.short.fri", 4), ("weekday.short.sat", 5),
        ("weekday.short.sun", 6),
    ]

    // 7 colunas flexíveis: cabe no iPhone SE (375 pt) sem rolagem
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 7
    )

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

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(days, id: \.index) { day in
                    DayChip(
                        dayKey: day.key,
                        dayIndex: day.index,
                        session: state.weekSessions[day.index]
                    ) {
                        state.weekSessions[day.index] = nextSession(state.weekSessions[day.index])
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
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
    let dayIndex: Int      // 0=seg … 6=dom
    let session: SessionType?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(LocalizedStringKey(dayKey))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
                Text(sessionLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
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

    // Calendar.weekdaySymbols: [dom, seg, ter, qua, qui, sex, sáb] (índices 0-6)
    // Nosso índice: seg=0 … dom=6 → Calendar índice = (dayIndex + 1) % 7
    private var calendarDayName: String {
        Calendar.current.weekdaySymbols[(dayIndex + 1) % 7]
    }

    private var accessibilityLabel: String {
        if let s = session {
            return String(
                format: String(localized: "onboarding.week.a11y.day_session"),
                calendarDayName, sessionLabel
            )
        } else {
            return String(
                format: String(localized: "onboarding.week.a11y.day_no_session"),
                calendarDayName
            )
        }
    }
}
