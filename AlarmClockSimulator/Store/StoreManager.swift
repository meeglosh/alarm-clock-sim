import StoreKit

enum IAPProductID: String, CaseIterable {
    case streakFreeze12h = "com.meeglosh.AlarmClockSimulator.streakFreeze12h"
    case unlimitedFreezesMonthly = "com.meeglosh.AlarmClockSimulator.unlimitedFreezes.monthly"
}

enum StoreError: Error {
    case failedVerification
}

/// StoreKit 2 wrapper. One instance per app, injected via the SwiftUI
/// environment; multiple instances would mean multiple competing
/// Transaction.updates listeners.
@MainActor
@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var isUnlimitedFreezeActive = false
    private(set) var loadErrorMessage: String?

    /// The game layer's hook for delivering consumable content. Consumable
    /// transactions stay unfinished until this is set and has run, so a
    /// purchase can never be finished without its effect being applied.
    @ObservationIgnored var onConsumableGranted: ((IAPProductID) -> Void)?

    @ObservationIgnored private var handledTransactionIDs = Set<UInt64>()
    @ObservationIgnored private nonisolated(unsafe) var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.process(result)
            }
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Call once at startup, after `onConsumableGranted` is wired, so
    /// transactions left unfinished by a crash or missed grant are replayed.
    func start() async {
        await loadProducts()
        await refreshEntitlements()
        await processUnfinishedTransactions()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: IAPProductID.allCases.map(\.rawValue))
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified = verification else {
                throw StoreError.failedVerification
            }
            await process(verification)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
        await processUnfinishedTransactions()
    }

    func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            await process(result)
        }
    }

    // MARK: - Private

    /// Single funnel for transactions from purchase(), Transaction.updates,
    /// and Transaction.unfinished. The handledTransactionIDs set keeps the
    /// overlapping sources from double-granting one transaction.
    private func process(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        guard !handledTransactionIDs.contains(transaction.id) else { return }

        switch transaction.productType {
        case .consumable:
            guard let grant = onConsumableGranted else { return }
            handledTransactionIDs.insert(transaction.id)
            if transaction.revocationDate == nil,
               let productID = IAPProductID(rawValue: transaction.productID) {
                grant(productID)
            }
            await transaction.finish()
        default:
            handledTransactionIDs.insert(transaction.id)
            if transaction.productType == .autoRenewable {
                await refreshEntitlements()
            }
            await transaction.finish()
        }
    }

    private func refreshEntitlements() async {
        var unlimitedActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == IAPProductID.unlimitedFreezesMonthly.rawValue,
               transaction.revocationDate == nil {
                unlimitedActive = true
            }
        }
        isUnlimitedFreezeActive = unlimitedActive
    }
}
