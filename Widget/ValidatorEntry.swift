import WidgetKit

struct ValidatorEntry: TimelineEntry {
    let date: Date
    let validatorIndex: Int
    let isHealthy: Bool
    let isSlashed: Bool
    let statusLabel: String
    let balanceETH: Double?
    let effectiveBalanceETH: Double?
    let pubKeyShort: String?
    let isError: Bool
    let errorMessage: String?

    static let placeholder = ValidatorEntry(
        date: .now,
        validatorIndex: 123456,
        isHealthy: true,
        isSlashed: false,
        statusLabel: "active_online",
        balanceETH: 32.0419,
        effectiveBalanceETH: 32.0,
        pubKeyShort: "…deadbeef",
        isError: false,
        errorMessage: nil
    )
}
