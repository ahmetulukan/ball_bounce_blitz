import 'package:flame/components.dart';

class Paddle extends PositionComponent {
  static const double paddleWidth = 100;
  static const double paddleHeight = 15;
  static const double speed = 500;

  Paddle() : super(
    position: Vector2(200, 350),
    size: Vector2(paddleWidth, paddleHeight),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  void move(double dx) {
    double newX = position.x + dx;
    newX = newX.clamp(paddleWidth / 2, 400 - paddleWidth / 2);
    position = Vector2(newX, position.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = position.x.clamp(paddleWidth / 2, 400 - paddleWidth / 2);
  }
}