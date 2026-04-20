import 'dart:math';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import '../components/enemy.dart';

class SpawnSystem extends Component {
  final Random _random = Random();
  double _spawnTimer = 0;
  double _spawnInterval = 2.0;
  int _difficultyLevel = 1;
  late BallBounceGame gameRef;

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer += dt;

    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnEnemy();
    }
  }

  void _spawnEnemy() {
    final x = 30.0 + _random.nextDouble() * 340;
    final enemy = EnemyFactory.create(x, _difficultyLevel, gameRef);
    gameRef.add(enemy);
  }

  void increaseDifficulty() {
    _difficultyLevel++;
    _spawnInterval = (_spawnInterval - 0.1).clamp(0.5, 2.0);
  }

  void reset() {
    _spawnTimer = 0;
    _spawnInterval = 2.0;
    _difficultyLevel = 1;
  }
}