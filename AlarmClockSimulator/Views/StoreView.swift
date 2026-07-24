import StoreKit
import SwiftUI

struct StoreView: View {
    @State private var store = StoreManager()
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Streak Freezes") {
                if store.products.isEmpty {
                    Text("Loading products…")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.products) { product in
                    productRow(product)
                }
            }

            if store.isUnlimitedFreezeActive {
                Section {
                    Label("Unlimited Streak Freezes active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            Section {
                Button("Restore Purchases") {
                    Task { await restore() }
                }
            }
        }
        .navigationTitle("Streak Freezes")
        .disabled(isPurchasing)
        .alert("Purchase Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func productRow(_ product: Product) -> some View {
        Button {
            Task { await purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.plain)
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            // Standalone screen, no game layer to apply the freeze effect yet —
            // finish consumables immediately here instead of deferring to it.
            if let transaction = try await store.purchase(product), transaction.productType == .consumable {
                await store.finishTransaction(transaction)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        do {
            try await store.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        StoreView()
    }
}
