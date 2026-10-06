import AppIntents
import WidgetKit

struct LockScreenStyleIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget.name")

    @Parameter(title: LocalizedStringResource("lock_style.param.title"),
               default: LockScreenStyle.destaque)
    var style: LockScreenStyle

    init() {}
    init(style: LockScreenStyle) { self.style = style }
}
