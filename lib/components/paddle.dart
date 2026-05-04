import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'ball.dart';

class Paddle extends PositionComponent with HasGameRef, DragCallbacks, TapCallbacks {
  static const double baseWidth = 110;
  static const double baseHeight = 18;
  double _currentWidth = baseWidth;
  double _targetWidth = baseWidth;
  bool _magnetActive = false;
  double _magnetTimer = 0;
  static const double magnetDuration = 5.0;

  final List<Vector2> _trailPositions = [];
  static const int maxTrail = 6;

  double? _dragStartX;

  Paddle() : super(
    size: Vector2(baseWidth, baseHeight),
    anchor: Anchor.topCenter,
  );

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 40);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_currentWidth != _targetWidth) {
      final diff = _targetWidth - _currentWidth;
      _currentWidth += diff * 5 * dt;
      if ((diff.abs()) < 0.5) _currentWidth = _targetWidth;
    }

    if (_magnetActive) {
      _magnetTimer -= dt;
      if (_magnetTimer <= 0) {
        _magnetActive = false;
      }
    }

    _trailPositions.insert(0, position.clone());
    if (_trailPositions.length > maxTrail) {
      _trailPositions.removeLast();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (position.y == 0) {
      position = Vector2(size.x / 2, size.y - 40);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x = (position.x + event.localDelta.x).clamp(
      _currentWidth / 2,
      gameRef.size.x - _currentWidth / 2,
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    _dragStartX = position.x;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _dragStartX = null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    position.x = event.localPosition.x.clamp(
      _currentWidth / 2,
      gameRef.size.x - _currentWidth / 2,
    );
  }

  void expand() {
    _targetWidth = baseWidth * 1.4;
    Future.delayed(const Duration(seconds: 8), () {
      _targetWidth = baseWidth;
    });
  }

  void activateMagnet() {
    _magnetActive = true;
    _magnetTimer = magnetDuration;
  }

  bool get isMagnetActive => _magnetActive;

  void applyMagnetForce(Ball ball, double dt) {
    if (!_magnetActive) return;
    final diff = position - ball.position;
    final dist = diff.length;
    if (dist < 200 && dist > 0) {
      diff.normalize();
      ball.velocity = ball.velocity + diff * 400 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _trailPositions.length; i++) {
      final alpha = ((1 - i / _trailPositions.length) * 0.3);
      final trailPaint = Paint()
        ..color = Color.fromARGB((alpha * 255).toInt(), 0, 188, 212)
        ..style = PaintingStyle.fill;

      final trailWidth = _currentWidth * (1 - i / _trailPositions.length * 0.5);
      final rect = Rect.fromCenter(
        center: Offset(_trailPositions[i].x, _trailPositions[i].y),
        width: trailWidth,
        height: baseHeight * (1 - i / _trailPositions.length * 0.3),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        trailPaint,
      );
    }

    final glowPaint = Paint()
      ..color = Color.fromARGB(80, 0, 188, 212)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: _currentWidth + 10,
          height: baseHeight + 10,
        ),
        const Radius.circular(10),
      ),
      glowPaint,
    );

    final mainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF00BCD4),
          const Color(0xFF0097A7),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: _currentWidth,
        height: baseHeight,
      ));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: _currentWidth,
          height: baseHeight,
        ),
        const Radius.circular(9),
      ),
      mainPaint,
    );

    final highlightPaint = Paint()
      ..color = Color.fromARGB(60, 255, 255, 255)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.x - _currentWidth / 2 + 8,
          position.y - baseHeight / 2,
          _currentWidth * 0.5,
          4,
        ),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    if (_magnetActive) {
      final magnetPaint = Paint()
        ..color = Color.fromARGB(150, 233, 30, 99)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(position.x, position.y),
        80 * (_magnetTimer / magnetDuration),
        magnetPaint,
      );
    }
  }

  Rect toRect() {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: _currentWidth,
      height: baseHeight,
    );
  }
}
