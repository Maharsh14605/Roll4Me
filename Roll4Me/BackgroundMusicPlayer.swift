import AVFoundation

final class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()

    private var player: AVAudioPlayer?
    private(set) var currentVolume: Double = 0.7   // <— remember last volume

    private init() {}

    // Called from HomeView
    func update(soundOn: Bool, volume: Double) {
        if soundOn {
            play(volume: volume)
        } else {
            stop()
        }
    }

    // Used when ducking / restoring from DiceSoundPlayer
    func setVolume(_ volume: Double) {
        let clamped = max(0.0, min(volume, 1.0))
        currentVolume = clamped
        player?.volume = Float(clamped)
    }

    private func play(volume: Double) {
        let clamped = max(0.0, min(volume, 1.0))
        currentVolume = clamped

        guard clamped > 0 else {
            stop()
            return
        }

        if player == nil {
            if let url = Bundle.main.url(forResource: "bg_music", withExtension: "mp3") {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1   // loop forever
                player?.prepareToPlay()
            }
        }

        guard let player = player else { return }
        player.volume = Float(clamped)
        if !player.isPlaying {
            player.play()
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
