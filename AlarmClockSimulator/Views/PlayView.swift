import SwiftUI

/// The in-run screen (counting and ringing). The background artwork's baked
/// clock digits are covered by a live LCD panel showing the real countdown;
/// ringing adds the warning banner, lightning bolts, clock shake, and the
/// glowing snooze button.
struct PlayView: View {
    @Environment(GameViewModel.self) private var game
    var onSheet: (GameSheet) -> Void
    var onSmash: () -> Void

    @State private var boltFlicker = false
    @State private var snoozePulse = false
    @State private var clockShakeT: CGFloat = 0
    @State private var hudExpanded = false

    private var isRinging: Bool { game.phase == .ringing }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let layout = SceneImageLayout(container: proxy.size)
                ZStack {
                    SceneArt(layout: layout)

                    lcdOverlay(layout)
                        .modifier(ShakeEffect(travel: 5, shakes: 9, animatableData: clockShakeT))

                    if isRinging {
                        bolts(layout)
                    }
                }
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, Palette.background.opacity(0.92)],
                startPoint: .init(x: 0.5, y: 0.6),
                endPoint: .init(x: 0.5, y: 0.95)
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                CollapsibleHUD(isExpanded: $hudExpanded, onRankTap: { onSheet(.leaderboard) })
                if isRinging {
                    ringingBanner
                }
                Spacer()
                controls
                GameTabBar { tab in
                    switch tab {
                    case .shop: onSheet(.shop)
                    case .missions: onSheet(.missions)
                    case .collection: onSheet(.collection)
                    case .stats: onSheet(.stats)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentColumn()
        }
        .onChange(of: isRinging) { _, ringing in
            if ringing { startRingingEffects() }
        }
        .onAppear {
            if isRinging { startRingingEffects() }
        }
    }

    // MARK: - LCD

    private func lcdOverlay(_ layout: SceneImageLayout) -> some View {
        // Covers the artwork's baked "06:30" screen region (fractions
        // measured against the full-bleed loader render).
        let rect = layout.rect(x: 0.325, y: 0.495, width: 0.485, height: 0.115)
        let digitColor = isRinging ? Palette.lcdOrange : Palette.lcdRed
        return RoundedRectangle(cornerRadius: rect.height * 0.16)
            .fill(Color(red: 0.03, green: 0.015, blue: 0.015))
            .overlay(
                VStack(spacing: rect.height * 0.07) {
                    Text(countdownText)
                        .font(LCDFont.digits(rect.height * 0.52))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .foregroundStyle(digitColor)
                        .shadow(color: digitColor.opacity(0.9), radius: 8)
                        .opacity(isRinging && snoozePulse ? 0.35 : 1)
                    Text(isRinging ? "WAKE UP NOW" : "RISE AND REGRET")
                        .font(.system(size: rect.height * 0.12, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .lineLimit(1)
                        .foregroundStyle(digitColor.opacity(0.8))
                        .shadow(color: digitColor.opacity(0.7), radius: 4)
                }
                .padding(.horizontal, rect.width * 0.05)
            )
            .frame(width: rect.width, height: rect.height)
            .clockGlassPerspective()
            .position(x: rect.midX, y: rect.midY)
    }

    private var countdownText: String {
        if isRinging {
            guard let since = game.ringingSince else { return "00:00" }
            let elapsed = game.displayNow.timeIntervalSince(since)
            let remaining = max(0, Int((game.configuration.missWindow - elapsed).rounded(.up)))
            return String(format: "00:%02d", remaining)
        }
        guard let next = game.nextAlarmDate else { return "--:--" }
        let remaining = max(0, Int(next.timeIntervalSince(game.displayNow).rounded(.up)))
        return String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    // MARK: - Ringing dressing

    private func bolts(_ layout: SceneImageLayout) -> some View {
        let positions: [(CGFloat, CGFloat, CGFloat)] = [
            (0.10, 0.46, -20), (0.90, 0.43, 25), (0.06, 0.60, 15), (0.94, 0.57, -18),
        ]
        return ForEach(Array(positions.enumerated()), id: \.offset) { _, spec in
            let rect = layout.rect(x: spec.0, y: spec.1, width: 0.001, height: 0.001)
            Image(systemName: "bolt.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Palette.lcdOrange)
                .shadow(color: Palette.lcdOrange.opacity(0.9), radius: 8)
                .rotationEffect(.degrees(spec.2))
                .opacity(boltFlicker ? 1 : 0.25)
                .position(x: rect.midX, y: rect.midY)
        }
    }

    private var ringingBanner: some View {
        VStack(spacing: 3) {
            HStack(spacing: 8) {
                Text("⚠️")
                Text("ALARM GOING OFF!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.25))
                Text("⚠️")
            }
            Text("WAKE UP NOW OR LOSE YOUR STREAK!")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.2, green: 0.04, blue: 0.02).opacity(0.88), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(red: 1, green: 0.42, blue: 0.25).opacity(0.6), lineWidth: 1.5)
        )
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        if isRinging {
            Button {
                game.snooze()
            } label: {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                        Text("SNOOZE")
                    }
                    Text("+10 MINUTES")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .opacity(0.75)
                }
            }
            .buttonStyle(ChunkyButtonStyle(style: .snooze, height: 72))
            .shadow(color: Palette.lcdOrange.opacity(snoozePulse ? 0.95 : 0.4), radius: snoozePulse ? 22 : 10)
        } else {
            countdownCaption
            Button {
                onSheet(.shop)
            } label: {
                Label("STREAK FREEZES", systemImage: "snowflake")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
            }
            .buttonStyle(ChunkyButtonStyle(style: .blue, height: 48))
        }
        HoldToSmashButton(onSmash: onSmash)
    }

    private var countdownCaption: some View {
        HStack(spacing: 8) {
            freezeStatus
            Spacer()
            Text("until the next alarm")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var freezeStatus: some View {
        if game.isFreezeActive(at: game.displayNow) {
            Label(freezeText, systemImage: "snowflake")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Palette.cyan)
                .shadow(color: Palette.cyan.opacity(0.8), radius: 5)
        }
    }

    private var freezeText: String {
        guard let expiry = game.freezeExpiry, expiry > game.displayNow else { return "PROTECTED" }
        let remaining = Int(expiry.timeIntervalSince(game.displayNow))
        return String(format: "PROTECTED %dh %02dm", remaining / 3600, (remaining % 3600) / 60)
    }

    private func startRingingEffects() {
        boltFlicker = false
        snoozePulse = false
        withAnimation(.easeInOut(duration: 0.24).repeatForever(autoreverses: true)) {
            boltFlicker = true
        }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            snoozePulse = true
        }
        shakeLoop()
    }

    private func shakeLoop() {
        guard isRinging else {
            clockShakeT = 0
            return
        }
        clockShakeT = 0
        withAnimation(.linear(duration: 0.7)) {
            clockShakeT = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            shakeLoop()
        }
    }
}

/// Deliberate destruction: hold for 0.7s while the ring fills. This is the
/// accidental-smash protection now that the hammer is a button, not a drag.
struct HoldToSmashButton: View {
    var onSmash: () -> Void
    @State private var pressing = false

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 10) {
                Text("💀")
                Text("HOLD TO SMASH")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.danger)
                Text("💀")
            }
            Text("END RUN • LOSE STREAK")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Palette.danger.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: ChunkyStyle.smash.gradient, startPoint: .top, endPoint: .bottom))
                if pressing {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Palette.danger.opacity(0.35))
                        .transition(.scale(scale: 0.2, anchor: .leading).combined(with: .opacity))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(ChunkyStyle.smash.borderColor, lineWidth: 2)
        )
        .shadow(color: Palette.danger.opacity(pressing ? 0.8 : 0.15), radius: pressing ? 16 : 5)
        .scaleEffect(pressing ? 1.03 : 1)
        .onLongPressGesture(minimumDuration: 0.7) {
            onSmash()
        } onPressingChanged: { isPressing in
            withAnimation(isPressing ? .linear(duration: 0.7) : .spring(duration: 0.3)) {
                pressing = isPressing
            }
        }
    }
}
