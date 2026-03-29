import WidgetKit

struct ValidatorTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = ValidatorEntry
    typealias Intent = ValidatorConfigurationIntent

    func placeholder(in context: Context) -> ValidatorEntry { .placeholder }

    func snapshot(for configuration: Intent, in context: Context) async -> ValidatorEntry {
        guard !context.isPreview else { return .placeholder }
        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<ValidatorEntry> {
        let entry = await fetchEntry(for: configuration)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date)
            ?? entry.date.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(next))
    }

    // MARK: - Private

    private func fetchEntry(for configuration: Intent) async -> ValidatorEntry {
        let index  = configuration.validatorIndex
        let apiKey = configuration.apiKey

        guard !apiKey.isEmpty else {
            return ValidatorEntry(
                date: .now,
                validatorIndex: index,
                isHealthy: false,
                isSlashed: false,
                statusLabel: "no_api_key",
                balanceETH: nil,
                effectiveBalanceETH: nil,
                pubKeyShort: nil,
                isError: true,
                errorMessage: "Edit widget to set your API key."
            )
        }

        do {
            let status = try await BeaconchainAPI.fetchValidatorStatus(
                validatorIndex: index,
                apiKey: apiKey
            )

            let changed = ValidatorStateStore.shared.recordState(
                index: status.index,
                isHealthy: status.isHealthy
            )
            if changed {
                NotificationManager.sendStateChangeNotification(
                    validatorIndex: status.index,
                    isHealthy: status.isHealthy,
                    statusLabel: status.statusLabel
                )
            }

            return ValidatorEntry(
                date: status.timestamp,
                validatorIndex: status.index,
                isHealthy: status.isHealthy,
                isSlashed: status.isSlashed,
                statusLabel: status.statusLabel,
                balanceETH: status.balanceETH,
                effectiveBalanceETH: status.effectiveBalanceETH,
                pubKeyShort: status.pubKeyShort,
                isError: false,
                errorMessage: nil
            )
        } catch {
            return ValidatorEntry(
                date: .now,
                validatorIndex: index,
                isHealthy: false,
                isSlashed: false,
                statusLabel: "error",
                balanceETH: nil,
                effectiveBalanceETH: nil,
                pubKeyShort: nil,
                isError: true,
                errorMessage: error.localizedDescription
            )
        }
    }
}
