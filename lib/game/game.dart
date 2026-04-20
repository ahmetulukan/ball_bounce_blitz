import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'scene/game_scene.dart';
import '../screens/home_screen.dart';

class BallBounceBlitzGame extends FlameGame with TapDetector, HasCollisionDetection {
  GameScene? _scene;
  bool _gameStarted = false;

  @override
  Future<void> onLoad() async {
    await images.load('paddle.png');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_gameStarted) {
      startGame();
    }
  }

  void startGame() {
    _gameStarted = true;
    _scene = GameScene();
    add(_scene!);
  }

  void showGameOverScreen(int score) {
    overlays.add('GameOver');
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_scene == null) startGame();
  }
}