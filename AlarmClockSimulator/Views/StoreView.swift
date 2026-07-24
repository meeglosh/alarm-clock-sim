import StoreKit
import SwiftUI

struct StoreView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Streak Freezes") {
                if let message = store.loadErrorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Couldn't load products.")
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await store.loadProducts() }
                        }
                    }
                } else if store.products.isEmpty {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading products…")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.products) { product in
                        productRow(product)
                    }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .disabled(isPurchasing)
        .overlay {
            if isPurchasing {
                ProgressView()
            }
        }
        .alert("Purchase Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
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
            try await store.purchase(product)
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
    .environment(StoreManager())
}
