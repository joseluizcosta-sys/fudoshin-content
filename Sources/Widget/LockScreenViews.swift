import SwiftUI
import WidgetKit

// MARK: - accessoryRectangular

struct RectangularView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.entry.shortText)
                .font(.caption)
                .minimumScaleFactor(0.8)
                .lineLimit(3)
            Text(attributionText(author: entry.entry.author, isParaphrase: entry.entry.isParaphrase))
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - accessoryInline

struct InlineView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        Text(entry.entry.inlineText)
            .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - accessoryCircular

struct CircularView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        Group {
            if let days = entry.entry.daysToRace, days >= 0 {
                // progress = 1 - (diasRestantes / diasTotais): 0 na criação, 1 no dia da prova.
                Gauge(value: entry.entry.gaugeProgress) {
                    EmptyView()
                } currentValueLabel: {
                    VStack(spacing: 0) {
                        Text("\(days)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6)
                        Text("widget.circular.days")
                            .font(.system(size: 9))
                    }
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Text("心")
                    .font(.system(size: 22))
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Previews

#Preview("Rectangular", as: .accessoryRectangular) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.preview
}

#Preview("Inline", as: .accessoryInline) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.preview
}

#Preview("Circular", as: .accessoryCircular) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.preview
}
