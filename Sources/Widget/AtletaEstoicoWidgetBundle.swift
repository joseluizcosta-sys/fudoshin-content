import SwiftUI
import WidgetKit

@main
struct AtletaEstoicoWidgetBundle: WidgetBundle {
    var body: some Widget {
        FudoshinWidget()
    }
}

// MARK: - FudoshinWidget

struct FudoshinWidget: Widget {
    let kind = "FudoshinWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: LockScreenStyleIntent.self,
            provider: DailyProvider()
        ) { entry in
            FudoshinWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.name")
        .description("widget.description")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
            .systemMedium,
            .systemLarge,
        ])
    }
}
