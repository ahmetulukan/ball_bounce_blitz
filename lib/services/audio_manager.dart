// Audio manager - stubs for sound effects
// To enable audio: add flame_audio to pubspec.yaml and uncomment

class AudioManager {
  static bool _muted = false;

  static Future<void> init() async {
    // TODO: add flame_audio to pubspec.yaml
    // try {
    //   await FlameAudio.audioCache.load('hit.wav');
    //   await FlameAudio.audioCache.load('score.wav');
    // } catch (_) {}
  }

  static void playHit() {
    if (_muted) return;
    // TODO: uncomment when flame_audio is added
    // try { FlameAudio.play('hit.wav', volume: 0.6); } catch (_) {}
  }

  static void playScore() {
    if (_muted) return;
    // try { FlameAudio.play('score.wav', volume: 0.7); } catch (_) {}
  }

  static void playPowerUp() {
    if (_muted) return;
    // try { FlameAudio.play('powerup.wav', volume: 0.8); } catch (_) {}
  }

  static void playGameOver() {
    if (_muted) return;
    // try { FlameAudio.play('gameover.wav', volume: 1.0); } catch (_) {}
  }

  static void toggleMute() => _muted = !_muted;
  static bool get muted => _muted;
}
