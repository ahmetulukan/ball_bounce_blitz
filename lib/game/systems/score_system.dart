import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

class ScoreSystem extends Component {
  late BallBounceGame gameRef;
  int highScore = 0;
  bool _initialized = false;

  void setGame(BallBounceGame game) {
    gameRef = game;
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    // High score persistence handled in game state
    _initialized = true;
  }

  void onGameOver(int finalScore) {
    if (finalScore > highScore) {
      highScore = finalScore;
      // Save high score
    }
  }

  int getHighScore() => highScore;

  void updateHighScore(int score) {
    if (score > highScore) {
      highScore = score;
    }
  }
}