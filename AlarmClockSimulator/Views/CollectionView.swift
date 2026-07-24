import SwiftUI

/// The museum of silenced clocks: a grid of collectibles unlocked by
/// lifetime milestones. Locked exhibits show as mystery silhouettes with
/// their unlock requirement and live progress.
struct CollectionView: View {
    @Environment(GameViewModel.self) private var game

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HeadlineGradientText(text: "COLLECTION", size: 36)
                    AccentPill(text: "CLOCKS YOU HAVE SILENCED")
                }
                .padding(.top, 40)

                summaryBar

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ClockCollection.all) { item in
                        exhibitCard(item)
                    }
                }

                Text("Silence more clocks to grow the museum. 🔨")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .contentColumn()
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
        .overlay(alignment: .topLeading) {
            SheetBackButton()
        }
    }

    private var summaryBar: some View {
        let unlocked = game.unlockedCollectionCount
        let total = ClockCollection.all.count
        return HStack(spacing: 12) {
            Text("🏛️").font(.system(size: 26))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unlocked) / \(total) SILENCED")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(Palette.gold)
                                .frame(width: proxy.size.width * CGFloat(unlocked) / CGFloat(total))
                        }
                    }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gamePanel()
    }

    @ViewBuilder
    private func exhibitCard(_ item: CollectionItem) -> some View {
        let unlocked = game.isUnlocked(item)
        VStack(spacing: 6) {
            Text(item.emoji)
                .font(.system(size: 34))
                .grayscale(unlocked ? 0 : 1)
                .opacity(unlocked ? 1 : 0.35)
                .shadow(color: unlocked ? Palette.gold.opacity(0.6) : .clear, radius: 8)
            Text(unlocked ? item.name : "???")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(unlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            if unlocked {
                Text(item.flavor)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            } else {
                Text(item.requirementText)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Palette.cyan.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("\(game.collectionProgress(item)) / \(item.threshold)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .top)
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .gamePanel(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(unlocked ? Palette.gold.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }
}
