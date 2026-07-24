import AVFoundation
import Observation

/// Looping menu music (Resources/menu_music.mp3, source in audio/) with
/// fade in/out and a persisted mute toggle. Plays on the loader,
/// disclaimer, main menu, and streak-ended screens; gameplay is music-free
/// so the alarm owns the room.
@MainActor
@Observable
final class MusicPlayer {
    /// Leaves headroom for the alarm and smash SFX.
    private static let normalVolume: Float = 0.55
    private static let mutedKey = "music.muted"

    private static let smolderVolume: Float = 0.4

    private(set) var isMuted: Bool

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var smolderPlayer: AVAudioPlayer?
    @ObservationIgnored private var pauseTask: Task<Void, Never>?
    /// Whether the current screen wants music/ambience, independent of
    /// mute, so unmuting can resume in place.
    @ObservationIgnored private var desiredPlaying = false
    @ObservationIgnored private var desiredSmoldering = false

    init() {
        isMuted = UserDefaults.standard.bool(forKey: Self.mutedKey)
        if let url = Bundle.main.url(forResource: "menu_music", withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0
            player?.prepareToPlay()
        }
        if let url = Bundle.main.url(forResource: "smolder", withExtension: "wav") {
            smolderPlayer = try? AVAudioPlayer(contentsOf: url)
            smolderPlayer?.numberOfLoops = -1
            smolderPlayer?.volume = 0
            smolderPlayer?.prepareToPlay()
        }
    }

    func fadeIn(duration: TimeInterval = 1.0) {
        desiredPlaying = true
        guard !isMuted else { return }
        performFadeIn(duration: duration)
    }

    func fadeOut(duration: TimeInterval = 0.8) {
        desiredPlaying = false
        performFadeOut(duration: duration)
    }

    /// Looping ember-crackle ambience for the wreckage screen. Follows the
    /// same mute rules as the music.
    func setSmoldering(_ active: Bool) {
        desiredSmoldering = active
        guard let smolderPlayer else { return }
        if active, !isMuted {
            if !smolderPlayer.isPlaying {
                smolderPlayer.play()
            }
            smolderPlayer.setVolume(Self.smolderVolume, fadeDuration: 0.8)
        } else {
            smolderPlayer.setVolume(0, fadeDuration: 0.4)
        }
    }

    func toggleMuted() {
        isMuted.toggle()
        UserDefaults.standard.set(isMuted, forKey: Self.mutedKey)
        if isMuted {
            performFadeOut(duration: 0.25)
            smolderPlayer?.setVolume(0, fadeDuration: 0.25)
        } else {
            if desiredPlaying {
                performFadeIn(duration: 0.6)
            }
            if desiredSmoldering {
                setSmoldering(true)
            }
        }
    }

    // MARK: - Private

    private func performFadeIn(duration: TimeInterval) {
        guard let player else { return }
        pauseTask?.cancel()
        pauseTask = nil
        if !player.isPlaying {
            player.play()
        }
        player.setVolume(Self.normalVolume, fadeDuration: duration)
    }

    private func performFadeOut(duration: TimeInterval) {
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
