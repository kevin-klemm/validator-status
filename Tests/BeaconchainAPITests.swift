import XCTest

final class BeaconchainAPIParseTests: XCTestCase {

    // MARK: - Happy path

    func testParseActiveOnlineValidator() throws {
        let json = """
        {
            "data": [{
                "validator": {
                    "index": 75075,
                    "public_key": "0xabcdef1234567890a3f9c12b"
                },
                "status": "active_online",
                "online": true,
                "slashed": false,
                "balances": {
                    "current": 32041928000,
                    "effective": 32000000000
                }
            }]
        }
        """
        let status = try parse(json)

        XCTAssertEqual(status.index, 75075)
        XCTAssertTrue(status.isActive)
        XCTAssertTrue(status.isOnline)
        XCTAssertFalse(status.isSlashed)
        XCTAssertTrue(status.isHealthy)
        XCTAssertEqual(status.statusLabel, "active_online")
        XCTAssertEqual(status.balanceETH!, 32.041928, accuracy: 0.000001)
        XCTAssertEqual(status.effectiveBalanceETH!, 32.0, accuracy: 0.000001)
        XCTAssertEqual(status.pubKeyShort, "…a3f9c12b")
    }

    func testParseActiveOfflineValidator() throws {
        let json = """
        {
            "data": [{
                "validator": { "index": 100 },
                "status": "active_offline",
                "online": false
            }]
        }
        """
        let status = try parse(json)

        XCTAssertFalse(status.isOnline)
        XCTAssertFalse(status.isHealthy)
        XCTAssertEqual(status.statusLabel, "active_offline")
        XCTAssertNil(status.balanceETH)
        XCTAssertNil(status.effectiveBalanceETH)
    }

    func testParsePendingValidator() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 200 }, "status": "pending_initialized", "online": false }] }
        """)

        XCTAssertFalse(status.isActive)
        XCTAssertFalse(status.isHealthy)
        XCTAssertEqual(status.statusLabel, "pending_initialized")
    }

    func testParseExitedValidator() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 300 }, "status": "exited_unslashed", "online": false, "slashed": false }] }
        """)

        XCTAssertFalse(status.isActive)
        XCTAssertFalse(status.isHealthy)
    }

    // MARK: - Slashed

    func testParseSlashedValidator() throws {
        let json = """
        {
            "data": [{
                "validator": { "index": 42 },
                "status": "active_slashed",
                "online": true,
                "slashed": true,
                "balances": { "current": 16000000000, "effective": 16000000000 }
            }]
        }
        """
        let status = try parse(json)

        XCTAssertTrue(status.isSlashed)
        XCTAssertFalse(status.isHealthy, "Slashed validator must not be healthy")
        XCTAssertEqual(status.balanceETH!, 16.0, accuracy: 0.000001)
        XCTAssertEqual(status.effectiveBalanceETH!, 16.0, accuracy: 0.000001)
    }

    // MARK: - Public key abbreviation

    func testPubKeyShortTakesLast8Chars() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1, "public_key": "0xAABBCCDDEEFF001122334455" }, "status": "active_online", "online": true }] }
        """)

        XCTAssertEqual(status.pubKeyShort, "…22334455")
    }

    func testShortPubKeyIsNilWhenMissing() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true }] }
        """)

        XCTAssertNil(status.pubKeyShort)
    }

    func testShortPubKeyIsNilForTooShortValue() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1, "public_key": "0x12" }, "status": "active_online", "online": true }] }
        """)

        XCTAssertNil(status.pubKeyShort)
    }

    // MARK: - Effective balance

    func testEffectiveBalanceAsInt() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true, "balances": { "current": 32100000000, "effective": 32000000000 } }] }
        """)

        XCTAssertEqual(status.effectiveBalanceETH!, 32.0, accuracy: 0.000001)
    }

    func testEffectiveBalanceAsDouble() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true, "balances": { "current": 32100000000.0, "effective": 32000000000.0 } }] }
        """)

        XCTAssertEqual(status.effectiveBalanceETH!, 32.0, accuracy: 0.000001)
    }

    // MARK: - Balance type variations

    func testParseBalanceAsDouble() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true, "balances": { "current": 32000000000.0 } }] }
        """)
        XCTAssertEqual(status.balanceETH!, 32.0, accuracy: 0.000001)
    }

    func testParseBalanceAsInt() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true, "balances": { "current": 32000000000 } }] }
        """)
        XCTAssertEqual(status.balanceETH!, 32.0, accuracy: 0.000001)
    }

    func testParseMissingBalances() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true }] }
        """)
        XCTAssertNil(status.balanceETH)
        XCTAssertNil(status.effectiveBalanceETH)
    }

    // MARK: - Fallback behaviour

    func testFallbackIndexUsedWhenMissing() throws {
        let status = try parse(
            """{ "data": [{ "validator": {}, "status": "active_online", "online": true }] }""",
            fallback: 42
        )
        XCTAssertEqual(status.index, 42)
    }

    func testMissingStatusDefaultsToUnknown() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "online": true }] }
        """)
        XCTAssertEqual(status.statusLabel, "unknown")
        XCTAssertFalse(status.isActive)
    }

    func testMissingOnlineDefaultsToFalse() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online" }] }
        """)
        XCTAssertFalse(status.isOnline)
        XCTAssertFalse(status.isHealthy)
    }

    func testMissingSlashedDefaultsToFalse() throws {
        let status = try parse("""
        { "data": [{ "validator": { "index": 1 }, "status": "active_online", "online": true }] }
        """)
        XCTAssertFalse(status.isSlashed)
    }

    // MARK: - Error cases

    func testParseEmptyDataArrayThrows() {
        XCTAssertThrowsError(try parse(#"{ "data": [] }"#))
    }

    func testParseInvalidJSONThrows() {
        XCTAssertThrowsError(
            try BeaconchainAPI.parseResponse(data: Data("not json".utf8), fallbackIndex: 1)
        )
    }

    func testParseMissingDataKeyThrows() {
        XCTAssertThrowsError(try parse(#"{ "validators": [] }"#))
    }

    // MARK: - Extra / unknown fields are tolerated

    func testExtraFieldsIgnored() throws {
        let json = """
        {
            "data": [{
                "validator": {
                    "index": 5,
                    "public_key": "0xAABBCCDDEEFF001122334455",
                    "withdrawal_credentials": "something"
                },
                "status": "active_online",
                "online": true,
                "slashed": false,
                "finality": "finalized",
                "life_cycle_epochs": {},
                "some_future_field": 123
            }],
            "paging": { "next_cursor": "abc" }
        }
        """
        let status = try parse(json)

        XCTAssertEqual(status.index, 5)
        XCTAssertTrue(status.isHealthy)
    }

    // MARK: - Helper

    private func parse(_ json: String, fallback: Int = 1) throws -> ValidatorStatus {
        try BeaconchainAPI.parseResponse(data: Data(json.utf8), fallbackIndex: fallback)
    }
}
