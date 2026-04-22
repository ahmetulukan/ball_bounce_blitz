import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'ball.dart';

class BallTrail extends Component {
  final Ball ball;
  final List<TrailPoint> points = [];
  final int maxPoints = 14;

  BallTrail({required this.ball});

  @override
  void update(double dt) {
    points.insert(0, TrailPoint(ball.position.clone(), ball.isBoosted));
    if (points.length > maxPoints) points.removeLast();
  }

  @override
  void render(Canvas canvas) {
    for (int i = points.length - 1; i >= 0; i--) {
      final p = points[i];
      final progress = i / maxPoints;
      final alpha = ((1 - progress) * 0.5).clamp(0.0, 0.5);
      final radius = (Ball.radius * 0.6 * (1 - progress * 0.7)).clamp(0.5, Ball.radius * 0.6);
      final color = p.boosted
          ? Color.fromARGB((alpha * 255).toInt(), 255, 152, 0)
          : Color.fromARGB((alpha * 255).toInt(), 255, 235, 59);
      final paint = Paint()..color = color;
      
      // Draw at the point's recorded position
      canvas.drawCircle(p.position.toOffset(), radius, paint);
    }
  }
}

class TrailPoint {
  final Vector2 position;
  final bool boosted;
  TrailPoint(this.position, this.boosted);
}
