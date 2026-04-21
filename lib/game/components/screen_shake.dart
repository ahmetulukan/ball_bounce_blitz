import 'dart:math';
import 'package:flame/components.dart';

class ScreenShake extends Component {
  double intensity = 0;
  double duration = 0;
  double _elapsed = 0;
  final Random _random = Random();

  void shake({double intensity = 5, double duration = 0.3}) {
    this.intensity = intensity;
    this.duration = duration;
    _elapsed = 0;
  }

  Vector2 get offset {
    if (_elapsed >= duration) return Vector2.zero();
    final progress = _elapsed / duration;
    final currentIntensity = intensity * (1 - progress);
    return Vector2(
      (_random.nextDouble() * 2 - 1) * currentIntensity,
      (_random.nextDouble() * 2 - 1) * currentIntensity,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  bool get isShaking => _elapsed < duration;
}
