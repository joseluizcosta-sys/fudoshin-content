import SwiftUI
import WidgetKit

// Cores do tema (Core/Shared/Theme.swift não é compilado no widget target).
private extension Color {
    static let wBg     = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let wAccent = Color(red: 0.95, green: 0.55, blue: 0.30)
    static let wText   = Color(red: 0.95, green: 0.94, blue: 0.92)
    static let wSub    = Color(red: 0.68, green: 0.69, blue: 0.71)
}

private var widgetGradient: LinearGradient {
    LinearGradient(
        colors: [Color.wBg, Color(red: 0.14, green: 0.10, blue: 0.08)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - systemMedium / systemLarge

struct HomeView: View {
    let entry: DailyWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            widgetGradient
            content
        }
        .containerBackground(for: .widget) { widgetGradient }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.entry.shortText)
                .font(family == .systemLarge ? .body.weight(.medium) : .subheadline.weight(.medium))
                .foregroundStyle(Color.wText)
                .lineLimit(family == .systemLarge ? 5 : 3)
                .minimumScaleFactor(0.85)

            Text(attributionText(author: entry.entry.author, isParaphrase: entry.entry.isParaphrase))
                .font(.caption)
                .foregroundStyle(Color.wSub)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let days = entry.entry.daysToRace, days >= 0 {
                Spacer(minLength: 4)
                daysLabel(days)
            }
        }
        .padding(14)
    }

    private func daysLabel(_ days: Int) -> some View {
        let fmt = String(localized: "widget.home.days.format")
        return Text(String(format: fmt, days))
            .font(.caption2)
            .foregroundStyle(Color.wAccent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.wAccent.opacity(0.15), in: Capsule())
    }
}

// MARK: - systemSmall / StandBy

struct SmallView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(entry.entry.inlineText)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(3)
                .foregroundStyle(Color.wText)

            Text("不動心")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.wSub)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { widgetGradient }
    }
}

// MARK: - Unified entry view

struct FudoshinWidgetEntryView: View {
    let entry: DailyWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:          SmallView(entry: entry)
            case .accessoryRectangular: RectangularView(entry: entry)
            case .accessoryInline:      InlineView(entry: entry)
            case .accessoryCircular:    CircularView(entry: entry)
            default:                    HomeView(entry: entry)
            }
        }
        .widgetURL(URL(string: "atletaestoico://today"))
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.preview
}

#Preview("Medium", as: .systemMedium) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.preview
}

#Preview("Large", as: .systemLarge) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.preview
}
