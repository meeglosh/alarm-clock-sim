import StoreKit

enum IAPProductID: String, CaseIterable {
    case streakFreeze12h = "com.meeglosh.AlarmClockSimulator.streakFreeze12h"
    case unlimitedFreezesMonthly = "com.meeglosh.AlarmClockSimulator.unlimitedFreezes.monthly"
}

enum StoreError: Error {
    case failedVerification
}

@MainActor
@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var isUnlimitedFreezeActive = false
    private(set) var lastError: Error?

    private nonisolated(unsafe) var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: IAPProductID.allCases.map(\.rawValue))
        } catch {
            lastError = error
        }
    }

    /// Returns the verified transaction so the caller can apply the purchase's
    /// effect (e.g. grant a streak freeze) before finishing it. Auto-renewable
    /// subscriptions are finished here immediately since there's no one-time
    /// effect to deliver — call `finishTransaction(_:)` for everything else.
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            if transaction.productType == .autoRenewable {
                await refreshEntitlements()
                await transaction.finish()
            }
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func finishTransaction(_ transaction: Transaction) async {
        await transaction.finish()
        await refreshEntitlements()
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var unlimitedActive = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == IAPProductID.unlimitedFreezesMonthly.rawValue,
               transaction.revocationDate == nil {
                unlimitedActive = true
            }
        }
        isUnlimitedFreezeActive = unlimitedActive
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self, let transaction = try? await self.checkVerified(result) else { continue }
                if transaction.productType == .autoRenewable {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
                // Consumables that arrive here (e.g. purchased on another
                // device) are intentionally left unfinished — only the game
                // layer that applies the freeze effect should finish them.
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
