import SwiftUI
import WidgetKit

// MARK: - accessoryRectangular

struct RectangularView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        textContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
    }

    @ViewBuilder
    private var textContent: some View {
        if entry.isSubscriptionRequired {
            Text("widget.no_subscription")
                .font(.system(size: 14, weight: .medium))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .widgetAccentable()
        } else {
            switch entry.style {
            case .destaque:
                Text(LockScreenContent.text(for: .destaque, entry: entry.entry))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .widgetAccentable()
            case .palavraChave:
                Text(LockScreenContent.text(for: .palavraChave, entry: entry.entry))
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .widgetAccentable()
            }
        }
    }
}

// MARK: - accessoryInline

struct InlineView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        Text(entry.isSubscriptionRequired
             ? String(localized: "widget.no_subscription")
             : entry.entry.inlineText)
            .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - accessoryCircular

struct CircularView: View {
    let entry: DailyWidgetEntry

    var body: some View {
        Group {
            if let days = entry.entry.daysToRace, days >= 0 {
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
// Usamos as entradas com estilo já definido; o sistema de preview do WidgetKit
// passa a entry diretamente para a view, sem chamar o provider.

#Preview("Rectangular – Destaque", as: .accessoryRectangular) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.previewLongDestaque
}

#Preview("Rectangular – Palavra-chave", as: .accessoryRectangular) {
    FudoshinWidget()
} timeline: {
    DailyWidgetEntry.previewLongPalavraChave
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
