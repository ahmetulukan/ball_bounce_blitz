import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool _muted = false;
  static bool _initialized = false;
  static bool _musicOn = true;
  static bool _sfxOn = true;

  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.load('hit.wav');
      await FlameAudio.audioCache.load('score.wav');
      await FlameAudio.audioCache.load('powerup.wav');
      await FlameAudio.audioCache.load('gameover.wav');
      await FlameAudio.audioCache.load('explosion.wav');
      await FlameAudio.audioCache.load('wave.wav');
      await FlameAudio.audioCache.load('lose.wav');
      await FlameAudio.audioCache.load('charge.wav');
      _initialized = true;
    } catch (e) {
      // Audio not available - continue silently
    }
  }

  static void playHit() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('hit.wav', volume: 0.6); } catch (_) {}
  }

  static void playScore() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('score.wav', volume: 0.7); } catch (_) {}
  }

  static void playPowerUp() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('powerup.wav', volume: 0.8); } catch (_) {}
  }

  static void playGameOver() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('gameover.wav', volume: 1.0); } catch (_) {}
  }

  static void playExplosion() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('explosion.wav', volume: 0.85); } catch (_) {}
  }

  static void playWave() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('wave.wav', volume: 0.6); } catch (_) {}
  }

  static void playLose() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('lose.wav', volume: 0.7); } catch (_) {}
  }

  static void playCharge() {
    if (_muted || !_sfxOn || !_initialized) return;
    try { FlameAudio.play('charge.wav', volume: 0.5); } catch (_) {}
  }

  /// Background music - loops a track
  static void playBackgroundMusic(String track, {double volume = 0.4}) {
    if (_muted || !_musicOn || !_initialized) return;
    try {
      FlameAudio.play(track, volume: volume);
    } catch (_) {}
  }

  static void stopBackgroundMusic() {
    try { FlameAudio.bgm.stop(); } catch (_) {}
  }

  static void pauseBackgroundMusic() {
    try { FlameAudio.bgm.pause(); } catch (_) {}
  }

  static void resumeBackgroundMusic() {
    if (!_muted && _musicOn) {
      try { FlameAudio.bgm.resume(); } catch (_) {}
    }
  }

  static void toggleMute() {
    _muted = !_muted;
    if (_muted) {
      stopBackgroundMusic();
    }
  }

  static void toggleMusic() => _musicOn = !_musicOn;
  static void toggleSfx() => _sfxOn = !_sfxOn;

  static bool get muted => _muted;
  static bool get musicOn => _musicOn;
  static bool get sfxOn => _sfxOn;
}
