import AVFoundation
import Observation

/// Looping menu music (Resources/menu_music.mp3, source in audio/) with
/// fade in/out. Plays on the loader, disclaimer, main menu, and
/// streak-ended screens; gameplay is music-free so the alarm owns the room.
@MainActor
@Observable
final class MusicPlayer {
    /// Leaves headroom for the alarm and smash SFX.
    private static let normalVolume: Float = 0.55

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var pauseTask: Task<Void, Never>?

    init() {
        guard let url = Bundle.main.url(forResource: "menu_music", withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = 0
        player?.prepareToPlay()
    }

    func fadeIn(duration: TimeInterval = 1.0) {
        guard let player else { return }
        pauseTask?.cancel()
        pauseTask = nil
        if !player.isPlaying {
            player.play()
        }
        player.setVolume(Self.normalVolume, fadeDuration: duration)
    }

    func fadeOut(duration: TimeInterval = 0.8) {
        guard let player, player.isPlaying else { return }
        pauseTask?.cancel()
        player.setVolume(0, fadeDuration: duration)
        pauseTask = Task { [weak player] in
            try? await Task.sleep(for: .seconds(duration + 0.1))
            guard !Task.isCancelled else { return }
            player?.pause()
        }
    }
}
