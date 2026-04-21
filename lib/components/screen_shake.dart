import 'package:flame/components.dart';
import '../../game/game.dart';

class ScreenShake extends Component with HasGameReference<BallBounceBlitzGame> {
  double intensity = 0;
  double duration = 0;
  double elapsed = 0;
  Vector2 offset = Vector2.zero();

  void trigger({double shakeIntensity = 5, double shakeDuration = 0.3}) {
    intensity = shakeIntensity;
    duration = shakeDuration;
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
        (DateTime.now().microsecond % 100 - 50) / 50 * currentIntensity,
        (DateTime.now().microsecond % 97 - 48) / 50 * currentIntensity,
      );
    } else {
      offset = Vector2.zero();
    }
  }

  Vector2 get shakeOffset => offset;
}