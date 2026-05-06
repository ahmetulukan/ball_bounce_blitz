import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class ScreenShake extends Component {
  double intensity = 0;
  double duration = 0;
  double _elapsed = 0;
  final Random _random = Random();
  double _offsetX = 0;
  double _offsetY = 0;

  Vector2 get offset => Vector2(_offsetX, _offsetY);

  void shake({required double intensity, required double duration}) {
    this.intensity = intensity;
    this.duration = duration;
    _elapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (duration > 0) {
      _elapsed += dt;
      if (_elapsed < duration) {
        final progress = _elapsed / duration;
        final currentIntensity = intensity * (1 - progress);
        _offsetX = (_random.nextDouble() * 2 - 1) * currentIntensity;
        _offsetY = (_random.nextDouble() * 2 - 1) * currentIntensity;
      } else {
        _offsetX = 0;
        _offsetY = 0;
        intensity = 0;
        duration = 0;
      }
    }
  }

  void reset() {
    _offsetX = 0;
    _offsetY = 0;
    intensity = 0;
    duration = 0;
    _elapsed = 0;
  }
}