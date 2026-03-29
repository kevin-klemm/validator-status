import XCTest

final class ValidatorStateStoreTests: XCTestCase {

    private var store: ValidatorStateStore!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")
        store = ValidatorStateStore(defaults: defaults)
    }

    override func tearDown() {
        store.reset()
        defaults.removePersistentDomain(forName: defaults.description)
        super.tearDown()
    }

    // MARK: - Initial state

    func testInitialStateIsNil() {
        XCTAssertNil(store.lastHealthy)
        XCTAssertNil(store.lastIndex)
    }

    // MARK: - First observation never counts as a change

    func testFirstRecordReturnsFalse() {
        let changed = store.recordState(index: 1, isHealthy: true)
        XCTAssertFalse(changed, "First observation should not be treated as a state change")
        XCTAssertEqual(store.lastIndex, 1)
        XCTAssertEqual(store.lastHealthy, true)
    }

    // MARK: - Same state → no change

    func testSameStateReturnsFalse() {
        store.recordState(index: 1, isHealthy: true)
        let changed = store.recordState(index: 1, isHealthy: true)
        XCTAssertFalse(changed)
    }

    // MARK: - Health flip → change

    func testHealthFlipReturnsTrue() {
        store.recordState(index: 1, isHealthy: true)
        let changed = store.recordState(index: 1, isHealthy: false)
        XCTAssertTrue(changed)
        XCTAssertEqual(store.lastHealthy, false)
    }

    func testHealthRecoveryReturnsTrue() {
        store.recordState(index: 1, isHealthy: false)
        let changed = store.recordState(index: 1, isHealthy: true)
        XCTAssertTrue(changed)
    }

    // MARK: - Index change → change

    func testIndexChangeReturnsTrue() {
        store.recordState(index: 1, isHealthy: true)
        let changed = store.recordState(index: 2, isHealthy: true)
        XCTAssertTrue(changed)
        XCTAssertEqual(store.lastIndex, 2)
    }

    // MARK: - Reset

    func testResetClearsState() {
        store.recordState(index: 1, isHealthy: true)
        store.reset()
        XCTAssertNil(store.lastHealthy)
        XCTAssertNil(store.lastIndex)
    }

    func testRecordAfterResetIsFirstObservation() {
        store.recordState(index: 1, isHealthy: true)
        store.reset()
        let changed = store.recordState(index: 1, isHealthy: false)
        XCTAssertFalse(changed, "Post-reset is a fresh first observation")
    }
}
