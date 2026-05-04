import 'dart:math';
import 'package:flame/components.dart';
import '../game/game.dart';

class ScreenShake extends Component with HasGameReference<BallBounceBlitzGame> {
  double intensity;
  double duration;
  double elapsed = 0;
  Vector2 offset = Vector2.zero();
  final Random _rand = Random();

  ScreenShake({this.intensity = 5, this.duration = 0.3}) {
    elapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (elapsed < duration) {
      elapsed += dt;
      final progress = elapsed / duration;
      final currentIntensity = intensity * (1 - progress);
      offset = Vector2(
        (_rand.nextDouble() * 2 - 1) * currentIntensity,
        (_rand.nextDouble() * 2 - 1) * currentIntensity,
      );
    } else {
      offset = Vector2.zero();
    }
  }

  Vector2 get shakeOffset => offset;
}
