import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import '../components/enemy.dart';

class ComboSystem extends Component {
  late BallBounceGame gameRef;
  int comboCount = 0;
  int maxCombo = 0;
  double comboTimer = 0;
  static const double comboTimeout = 3.0;

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  int get currentCombo => comboCount;
  double get multiplier => _calculateMultiplier();

  double get timerRatio => comboTimer > 0 ? (comboTimer / comboTimeout).clamp(0.0, 1.0) : 0.0;

  double _calculateMultiplier() {
    if (comboCount < 5) return 1.0;
    if (comboCount < 10) return 1.5;
    if (comboCount < 20) return 2.0;
    if (comboCount < 30) return 2.5;
    return 3.0;
  }

  void onEnemyDestroyed(Enemy enemy) {
    comboCount++;
    if (comboCount > maxCombo) maxCombo = comboCount;
    comboTimer = comboTimeout;

    final basePoints = enemy.points;
    final bonusPoints = (basePoints * (multiplier - 1)).round();
    gameRef.score += bonusPoints;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        comboCount = 0;
        comboTimer = 0;
      }
    }
  }

  void reset() {
    comboCount = 0;
    comboTimer = 0;
  }

  String get comboText {
    if (comboCount < 5) return '';
    if (comboCount < 10) return '🔥 x1.5';
    if (comboCount < 20) return '🔥🔥 x2.0';
    if (comboCount < 30) return '🔥🔥🔥 x2.5';
    return '🔥🔥🔥🔥 x3.0';
  }

  String get comboEmoji {
    if (comboCount >= 15) return '🔥🔥🔥';
    if (comboCount >= 10) return '🔥🔥';
    if (comboCount >= 5) return '🔥';
    return '⚡';
  }
}
