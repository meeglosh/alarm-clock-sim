import StoreKitTest
import XCTest
@testable import AlarmClockSimulator

// These tests drive StoreManager against a local StoreKit test session
// (Configuration.storekit). They must be run from Xcode's Test navigator
// (Cmd+U) — `xcodebuild test` from the command line doesn't push the
// StoreKit configuration to the simulator's storekitd, so SKTestSession
// fails to resolve a storefront and every product lookup returns empty.
@MainActor
final class StoreManagerTests: XCTestCase {
    var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Configuration")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDown() {
        session = nil
    }

    func testLoadsConfiguredProducts() async throws {
        let store = StoreManager()
        await store.loadProducts()

        XCTAssertNil(store.loadErrorMessage)
        XCTAssertEqual(store.products.count, 2)
        XCTAssertTrue(store.products.contains { $0.id == IAPProductID.streakFreeze12h.rawValue })
        XCTAssertTrue(store.products.contains { $0.id == IAPProductID.unlimitedFreezesMonthly.rawValue })
    }

    func testConsumablePurchaseGrantsThroughHandler() async throws {
        let store = StoreManager()
        var granted: [IAPProductID] = []
        store.onConsumableGranted = { granted.append($0) }
        await store.loadProducts()
        let product = try XCTUnwrap(store.products.first { $0.id == IAPProductID.streakFreeze12h.rawValue })

        try await store.purchase(product)

        XCTAssertEqual(granted, [.streakFreeze12h])
    }

    func testSubscriptionPurchaseActivatesEntitlement() async throws {
        let store = StoreManager()
        await store.loadProducts()
        let product = try XCTUnwrap(store.products.first { $0.id == IAPProductID.unlimitedFreezesMonthly.rawValue })

        try await store.purchase(product)

        XCTAssertTrue(store.isUnlimitedFreezeActive)
    }
}
