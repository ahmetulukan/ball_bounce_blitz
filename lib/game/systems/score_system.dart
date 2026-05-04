import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

class ScoreSystem extends Component {
  late BallBounceGame gameRef;
  int highScore = 0;

  void setGame(BallBounceGame game) {
    gameRef = game;
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    // High score persistence handled in game state
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