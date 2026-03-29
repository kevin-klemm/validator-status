import SwiftUI
import WidgetKit

struct ValidatorWidget: Widget {
    let kind = "ValidatorStatusWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ValidatorConfigurationIntent.self,
            provider: ValidatorTimelineProvider()
        ) { entry in
            ValidatorWidgetView(entry: entry)
        }
        .configurationDisplayName("Validator Status")
        .description("Monitors an Ethereum validator via beaconcha.in.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
