import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool _initialized = false;
  static bool _muted = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.load('hit.wav');
      await FlameAudio.audioCache.load('score.wav');
      await FlameAudio.audioCache.load('powerup.wav');
      await FlameAudio.audioCache.load('gameover.wav');
      _initialized = true;
    } catch (e) {
      // Audio not available
      _initialized = false;
    }
  }

  static void playHit() {
    if (_muted || !_initialized) return;
    try { FlameAudio.play('hit.wav', volume: 0.6); } catch (_) {}
  }

  static void playScore() {
    if (_muted || !_initialized) return;
    try { FlameAudio.play('score.wav', volume: 0.7); } catch (_) {}
  }

  static void playPowerUp() {
    if (_muted || !_initialized) return;
    try { FlameAudio.play('powerup.wav', volume: 0.8); } catch (_) {}
  }

  static void playGameOver() {
    if (_muted || !_initialized) return;
    try { FlameAudio.play('gameover.wav', volume: 1.0); } catch (_) {}
  }

  static void toggleMute() => _muted = !_muted;
  static bool get muted => _muted;
}