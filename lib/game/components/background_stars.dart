import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class BackgroundStars extends Component {
  final Random _random = Random();
  final List<_Star> _stars = [];
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (int i = 0; i < 50; i++) {
      _stars.add(_Star(
        position: Vector2(
          _random.nextDouble() * 400,
          _random.nextDouble() * 400,
        ),
        size: _random.nextDouble() * 2 + 1,
        speed: _random.nextDouble() * 30 + 10,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final star in _stars) {
      star.position.y += star.speed * dt;
      if (star.position.y > 400) {
        star.position.y = 0;
        star.position.x = _random.nextDouble() * 400;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    for (final star in _stars) {
      paint.color = const Color(0xFFFFFFFF).withOpacity(0.3 + star.size * 0.3);
      canvas.drawCircle(star.position.toOffset(), star.size, paint);
    }
  }
}

class _Star {
  Vector2 position;
  double size;
  double speed;

  _Star({required this.position, required this.size, required this.speed});
}