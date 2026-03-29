import AppIntents

struct ValidatorConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Validator Status"
    static var description: IntentDescription = "Monitor an Ethereum validator via beaconcha.in."

    @Parameter(title: "Validator Index", default: 1)
    var validatorIndex: Int

    @Parameter(title: "API Key", default: "")
    var apiKey: String
}
