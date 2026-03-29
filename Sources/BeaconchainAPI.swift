import Foundation

// MARK: - Parsed result

struct ValidatorStatus: Equatable {
    let index: Int
    let isActive: Bool
    let isOnline: Bool
    let isSlashed: Bool
    let statusLabel: String
    let balanceETH: Double?
    let effectiveBalanceETH: Double?
    /// Last 8 hex chars of the public key, e.g. "…a3f9c12b"
    let pubKeyShort: String?
    let timestamp: Date

    var isHealthy: Bool { isActive && isOnline && !isSlashed }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.index == rhs.index
            && lhs.isActive == rhs.isActive
            && lhs.isOnline == rhs.isOnline
            && lhs.isSlashed == rhs.isSlashed
            && lhs.statusLabel == rhs.statusLabel
            && lhs.balanceETH == rhs.balanceETH
            && lhs.effectiveBalanceETH == rhs.effectiveBalanceETH
    }
}

// MARK: - API client

enum BeaconchainAPI {

    static let endpoint = URL(string: "https://beaconcha.in/api/v2/ethereum/validators")!

    static func fetchValidatorStatus(
        validatorIndex: Int,
        apiKey: String,
        session: URLSession = .shared
    ) async throws -> ValidatorStatus {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "validator": ["validator_identifiers": [validatorIndex]],
            "chain": "mainnet",
            "page_size": 1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }

        return try parseResponse(data: data, fallbackIndex: validatorIndex)
    }

    /// Parse raw JSON into a `ValidatorStatus`. Exposed for unit testing.
    static func parseResponse(data: Data, fallbackIndex: Int) throws -> ValidatorStatus {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataArray = root["data"] as? [[String: Any]],
            let first = dataArray.first
        else {
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            throw APIError.parseFailed(raw: String(raw.prefix(1000)))
        }

        // Identity
        let validatorObj = first["validator"] as? [String: Any]
        let resolvedIndex = validatorObj?["index"] as? Int ?? fallbackIndex
        let pubKeyShort: String? = {
            guard let key = validatorObj?["public_key"] as? String, key.count > 8 else {
                return nil
            }
            return "…" + key.suffix(8)
        }()

        // Status
        let statusString = first["status"] as? String ?? "unknown"
        let isActive  = statusString.hasPrefix("active")
        let isOnline  = first["online"]  as? Bool ?? false
        let isSlashed = first["slashed"] as? Bool ?? false

        // Balances — tolerate Int or Double from JSON
        var balanceETH: Double?
        var effectiveBalanceETH: Double?
        if let balances = first["balances"] as? [String: Any] {
            balanceETH          = gweiToETH(balances["current"])
            effectiveBalanceETH = gweiToETH(balances["effective"])
        }

        return ValidatorStatus(
            index: resolvedIndex,
            isActive: isActive,
            isOnline: isOnline,
            isSlashed: isSlashed,
            statusLabel: statusString,
            balanceETH: balanceETH,
            effectiveBalanceETH: effectiveBalanceETH,
            pubKeyShort: pubKeyShort,
            timestamp: Date()
        )
    }

    // MARK: - Helpers

    private static func gweiToETH(_ value: Any?) -> Double? {
        if let d = value as? Double { return d / 1_000_000_000.0 }
        if let i = value as? Int    { return Double(i) / 1_000_000_000.0 }
        return nil
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int)
        case parseFailed(raw: String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:      return "Invalid server response."
            case .httpError(let code):  return "HTTP \(code)."
            case .parseFailed(let raw): return "Parse error. Body: \(raw)"
            }
        }
    }
}
