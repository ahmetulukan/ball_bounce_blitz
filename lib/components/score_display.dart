import 'package:flame/components.dart';
import '../game/game.dart';

class ScoreDisplay extends TextComponent with HasGameReference<BallBounceBlitzGame> {
  ScoreDisplay() : super(text: 'Score: 0', anchor: Anchor.topCenter) {
    position = Vector2(game.size.x / 2, 20);
  }

  void updateScore(int score) {
    text = 'Score: $score';
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, 20);
  }
}
