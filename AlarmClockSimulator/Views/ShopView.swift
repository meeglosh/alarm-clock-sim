import StoreKit
import SwiftUI

/// The Streak Freeze shop, with the unlimited subscription a push away.
/// StoreKit wiring is unchanged; this is the designed storefront over it.
struct ShopView: View {
    @Environment(StoreManager.self) private var store
    @Environment(GameViewModel.self) private var game
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var freezeProduct: Product? {
        store.products.first { $0.id == IAPProductID.streakFreeze12h.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        HeadlineGradientText(
                            text: "STREAK FREEZE",
                            size: 38,
                            colors: [Color(red: 0.75, green: 0.93, blue: 1.0), Color(red: 0.35, green: 0.65, blue: 0.9)]
                        )
                        AccentPill(text: "12 HOURS OF PEACE")
                        Text("Take a breather without losing your streak.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    HeroImage(name: "heroFreeze", height: 210)

                    freezeStatusBanner

                    if let message = store.loadErrorMessage {
                        VStack(spacing: 8) {
                            Text("Couldn't load products.")
                                .foregroundStyle(.white)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Button("TRY AGAIN") {
                                Task { await store.loadProducts() }
                            }
                            .buttonStyle(ChunkyButtonStyle(style: .blue, height: 42))
                        }
                        .padding(14)
                        .gamePanel()
                    } else {
                        purchaseCard
                    }

                    NavigationLink {
                        UnlimitedFreezeView()
                    } label: {
                        HStack(spacing: 12) {
                            Text("♾️").font(.system(size: 30))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Want unlimited protection?")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("See Unlimited Freeze.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(red: 0.72, green: 0.55, blue: 1.0))
                            }
                            Spacer()
                            Text("VIEW  ›")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    LinearGradient(colors: ChunkyStyle.purple.gradient, startPoint: .top, endPoint: .bottom),
                                    in: Capsule()
                                )
                        }
                        .padding(14)
                        .background(Color(red: 0.13, green: 0.09, blue: 0.22).opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(red: 0.42, green: 0.25, blue: 0.7), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 0) {
                        featureCell("shield.checkered", "Protects your current streak")
                        Rectangle().fill(Palette.panelBorder).frame(width: 1, height: 52)
                        featureCell("clock.fill", "Expires after 12 hours")
                        Rectangle().fill(Palette.panelBorder).frame(width: 1, height: 52)
                        featureCell("calendar.badge.checkmark", "Use when life gets busy")
                    }
                    .padding(.vertical, 12)
                    .gamePanel()

                    Label("Freeze starts immediately after purchase.", systemImage: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))

                    Button("Restore Purchases") {
                        Task { await restore() }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.cyan)
                }
                .padding(16)
                .contentColumn()
            }
            .background(Palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("BACK", systemImage: "arrow.left")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(Palette.background, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .disabled(isPurchasing)
        .overlay { if isPurchasing { ProgressView().controlSize(.large) } }
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
    private var freezeStatusBanner: some View {
        if let expiry = game.freezeExpiry, expiry > Date() {
            Label("Freeze active until \(expiry.formatted(date: .omitted, time: .shortened))", systemImage: "snowflake")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.cyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .gamePanel(cornerRadius: 12)
        }
    }

    private var purchaseCard: some View {
        HStack(spacing: 14) {
            Text("❄️")
                .font(.system(size: 40))
                .shadow(color: Palette.cyan.opacity(0.9), radius: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Freeze your streak")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("for 12 hours")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.cyan)
            }
            Spacer()
            VStack(spacing: 8) {
                Text(freezeProduct?.displayPrice ?? "$1.99")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.gold)
                Button("BUY FREEZE") {
                    Task { await purchaseFreeze() }
                }
                .buttonStyle(ChunkyButtonStyle(style: .gold, height: 40))
                .frame(width: 150)
                .disabled(freezeProduct == nil)
            }
        }
        .padding(16)
        .background(Color(red: 0.07, green: 0.12, blue: 0.2).opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.cyan.opacity(0.35), lineWidth: 1.5))
    }

    private func featureCell(_ icon: String, _ text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.cyan)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func purchaseFreeze() async {
        guard let product = freezeProduct else { return }
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

/// The $4.99/month unlimited streak protection subscription screen.
struct UnlimitedFreezeView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var subscriptionProduct: Product? {
        store.products.first { $0.id == IAPProductID.unlimitedFreezesMonthly.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HeadlineGradientText(text: "UNLIMITED", size: 40)
                    HeadlineGradientText(
                        text: "FREEZE",
                        size: 40,
                        colors: [Color(white: 0.98), Color(white: 0.62)]
                    )
                    AccentPill(text: "UNLIMITED STREAK PROTECTION")
                }

                HeroImage(name: "heroUnlimited", height: 230)

                if store.isUnlimitedFreezeActive {
                    Label("Unlimited Streak Freezes active", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .gamePanel()
                } else {
                    subscriptionCard
                }

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        featureCell("🛡️", "Unlimited streak protection", "Never lose your streak again.")
                        featureCell("🗓️", "Great for chaotic schedules", "Life happens. We've got you.")
                    }
                    HStack(spacing: 0) {
                        featureCell("⚡️", "Never lose momentum", "During real-life emergencies.")
                        featureCell("✅", "Cancel anytime", "No long-term commitments.")
                    }
                }
                .padding(.vertical, 6)
                .gamePanel()

                Label("Subscription renews monthly unless cancelled.", systemImage: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(16)
            .contentColumn()
        }
        .background(Palette.background)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .preferredColorScheme(.dark)
        .disabled(isPurchasing)
        .overlay { if isPurchasing { ProgressView().controlSize(.large) } }
        .alert("Purchase Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var subscriptionCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Text("❄️")
                    .font(.system(size: 34))
                    .shadow(color: Palette.cyan.opacity(0.9), radius: 8)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(subscriptionProduct?.displayPrice ?? "$4.99")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ MO")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Text("Unlimited streak freezes")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.cyan)
                }
                Spacer()
                Text("MOST\nPOPULAR")
                    .font(.system(size: 10, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.cyan)
                    .padding(6)
                    .background(Palette.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            Button {
                Task { await subscribe() }
            } label: {
                HStack(spacing: 8) {
                    Text("START SUBSCRIPTION")
                    Image(systemName: "play.circle.fill")
                }
                .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .buttonStyle(ChunkyButtonStyle(style: .gold, height: 54))
            .disabled(subscriptionProduct == nil)
        }
        .padding(16)
        .background(Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.cyan.opacity(0.3), lineWidth: 1.5))
    }

    private func featureCell(_ emoji: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }

    private func subscribe() async {
        guard let product = subscriptionProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await store.purchase(product)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
