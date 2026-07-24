import SwiftUI

/// Idle-phase home screen over the full title artwork: collapsible HUD in
/// the corners, PLAY, leaderboard/settings, daily challenge, tab bar. The
/// art sits at its natural top-anchored position so the title, clock, and
/// hammer all read exactly as composed.
struct MainMenuView: View {
    @Environment(GameViewModel.self) private var game
    var onSheet: (GameSheet) -> Void
    var onPlay: () -> Void

    @State private var hudExpanded = false

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                CollapsibleHUD(
                    isExpanded: $hudExpanded,
                    onRankTap: { onSheet(.leaderboard) }
                )
                Spacer()
                Button {
                    onPlay()
                } label: {
                    HStack(spacing: 10) {
                        Text("PLAY")
                        Image(systemName: "play.circle.fill")
                    }
                }
                .buttonStyle(ChunkyButtonStyle(style: .gold, height: 62))

                HStack(spacing: 12) {
                    Button {
                        onSheet(.leaderboard)
                    } label: {
                        Label("LEADERBOARD", systemImage: "trophy.fill")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .buttonStyle(ChunkyButtonStyle(style: .blue, height: 48))

                    Button {
                        onSheet(.settings)
                    } label: {
                        Label("SETTINGS", systemImage: "gearshape.fill")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .buttonStyle(ChunkyButtonStyle(style: .purple, height: 48))
                }

                DailyChallengeBar()
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
        .background {
            ZStack {
                Palette.background
                GeometryReader { geo in
                    let layout = SceneImageLayout(container: geo.size)
                    ZStack {
                        SceneArt(layout: layout)
                        currentTimeOverlay(layout)
                    }
                }
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.58),
                        .init(color: Palette.background.opacity(0.95), location: 0.80),
                        .init(color: Palette.background, location: 0.97),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            HUDCornerButtons(isExpanded: $hudExpanded, showsMusicToggle: true)
                .padding(.horizontal, 16)
                .contentColumn()
                .padding(.top, 6)
                .ignoresSafeArea(edges: .top)
        }
    }

    /// The menu clock shows the player's actual time, replacing the
    /// artwork's baked "06:30" via the same LCD treatment (and perspective)
    /// the play screen uses for its countdown.
    private func currentTimeOverlay(_ layout: SceneImageLayout) -> some View {
        let rect = layout.rect(x: 0.325, y: 0.495, width: 0.485, height: 0.115)
        return TimelineView(.everyMinute) { context in
            let (digits, meridiem) = clockText(for: context.date)
            RoundedRectangle(cornerRadius: rect.height * 0.16)
                .fill(Color(red: 0.03, green: 0.015, blue: 0.015))
                .overlay(
                    VStack(spacing: rect.height * 0.07) {
                        HStack(alignment: .lastTextBaseline, spacing: rect.width * 0.03) {
                            Text(digits)
                                .font(LCDFont.digits(rect.height * 0.52))
                                .lineLimit(1)
                                .minimumScaleFactor(0.4)
                            Text(meridiem)
                                .font(.system(size: rect.height * 0.16, weight: .heavy, design: .monospaced))
                        }
                        .foregroundStyle(Palette.lcdRed)
                        .shadow(color: Palette.lcdRed.opacity(0.9), radius: 8)
                        Text("RISE AND REGRET")
                            .font(.system(size: rect.height * 0.12, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .lineLimit(1)
                            .foregroundStyle(Palette.lcdRed.opacity(0.8))
                            .shadow(color: Palette.lcdRed.opacity(0.7), radius: 4)
                    }
                    .padding(.horizontal, rect.width * 0.05)
                )
                .frame(width: rect.width, height: rect.height)
                .clockGlassPerspective()
                .position(x: rect.midX, y: rect.midY)
        }
    }

    private func clockText(for date: Date) -> (String, String) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour24 = components.hour ?? 0
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let digits = String(format: "%d:%02d", hour12, components.minute ?? 0)
        return (digits, hour24 < 12 ? "AM" : "PM")
    }
}
