import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

class TipSystem extends Component {
  late BallBounceGame gameRef;
  TipDisplay? _currentTip;
  double _tipTimer = 0;
  static const double _tipDuration = 4.0;
  static const double _tipInterval = 15.0;
  double _intervalTimer = 0;
  int _tipIndex = 0;

  static const List<_TipEntry> _tips = [
    _TipEntry(
      title: '🎯 Combo Master',
      text: 'Keep hitting enemies in succession to build your combo multiplier!',
      icon: '🔥',
    ),
    _TipEntry(
      title: '🧲 Magnet Power-up',
      text: 'Collect the magnet to attract nearby power-ups automatically!',
      icon: '🧲',
    ),
    _TipEntry(
      title: '⚡ Charge Shot',
      text: 'Hold the screen to charge a powerful shot that destroys all enemies!',
      icon: '⚡',
    ),
    _TipEntry(
      title: '🛡️ Shield',
      text: 'The shield power-up protects you from losing a life for 5 seconds!',
      icon: '🛡️',
    ),
    _TipEntry(
      title: '💥 Explosive',
      text: 'Explosive power-up creates a massive blast that destroys nearby enemies!',
      icon: '💥',
    ),
    _TipEntry(
      title: '🔥 Fireball Mode',
      text: 'Fireball speeds up your ball and deals bonus damage to enemies!',
      icon: '🔥',
    ),
    _TipEntry(
      title: '⏱️ Slow Motion',
      text: 'Slow-mo gives you more time to react and plan your moves!',
      icon: '⏱️',
    ),
    _TipEntry(
      title: '👾 Boss Waves',
      text: 'Every 5th wave brings a powerful boss enemy - prepare yourself!',
      icon: '👾',
    ),
    _TipEntry(
      title: '🔫 Laser Mode',
      text: 'Laser shoots automatic beams that destroy enemies on contact!',
      icon: '🔫',
    ),
    _TipEntry(
      title: '🌊 Wave Formations',
      text: 'Watch out for special wave formations - they spawn enemies in patterns!',
      icon: '🌊',
    ),
  ];

  void reset() {
    _currentTip = null;
    _tipTimer = 0;
    _intervalTimer = 0;
    _tipIndex = 0;
  }

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isGameOver || gameRef.isPaused) return;

    _intervalTimer += dt;

    if (_currentTip != null) {
      _tipTimer += dt;
      if (_tipTimer >= _tipDuration) {
        _currentTip = null;
        _tipTimer = 0;
      }
    } else if (_intervalTimer >= _tipInterval) {
      _intervalTimer = 0;
      _showNextTip();
    }
  }

  void _showNextTip() {
    final tip = _tips[_tipIndex % _tips.length];
    _tipIndex++;
    _currentTip = TipDisplay(
      title: tip.title,
      text: tip.text,
      onComplete: () {},
    );
    gameRef.add(_currentTip!);
  }

  void showTip(String title, String text) {
    // Immediate tip display for specific moments
    _currentTip?.removeFromParent();
    _currentTip = TipDisplay(
      title: title,
      text: text,
      onComplete: () {},
    );
    _tipTimer = 0;
    gameRef.add(_currentTip!);
  }
  void reset() {
    _currentTip = null;
    _tipTimer = 0;
    _intervalTimer = 0;
    _tipIndex = 0;
  }
}

class _TipEntry {
  final String title;
  final String text;
  final String icon;
  const _TipEntry({required this.title, required this.text, required this.icon});
}

class TipDisplay extends PositionComponent with HasGameReference {
  static const double _tipWidth = 280;
  static const double _tipHeight = 80;

  final String title;
  final String text;
  final VoidCallback onComplete;

  double _age = 0;
  static const double _fadeInDuration = 0.4;
  static const double _displayDuration = 3.5;
  static const double _fadeOutDuration = 0.4;
  static const double _totalDuration = _fadeInDuration + _displayDuration + _fadeOutDuration;

  late TextPainter _titlePainter;
  late TextPainter _textPainter;

  TipDisplay({
    required this.title,
    required this.text,
    required this.onComplete,
  }) : super(
          position: Vector2(200, 50),
          size: Vector2(_tipWidth, _tipHeight),
          anchor: Anchor.topCenter,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _titlePainter.layout(maxWidth: _tipWidth - 20);

    _textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _textPainter.layout(maxWidth: _tipWidth - 20);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;

    if (_age >= _totalDuration) {
      onComplete();
      removeFromParent();
    }
  }

  double get _opacity {
    if (_age < _fadeInDuration) {
      return (_age / _fadeInDuration).clamp(0.0, 1.0);
    } else if (_age > _displayDuration + _fadeInDuration) {
      final fadeOutAge = _age - _displayDuration - _fadeInDuration;
      return (1.0 - fadeOutAge / _fadeOutDuration).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  @override
  void render(Canvas canvas) {
    final opacity = _opacity;

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withAlpha((180 * opacity).round());
    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: _tipWidth,
        height: _tipHeight,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // Border glow
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha((100 * opacity).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bgRRect, borderPaint);

    // Title
    canvas.save();
    canvas.translate(-_tipWidth / 2 + 15, -_tipHeight / 2 + 10);
    _titlePainter.paint(canvas, Offset.zero);
    canvas.restore();

    // Text
    canvas.save();
    canvas.translate(-_tipWidth / 2 + 15, -_tipHeight / 2 + 32);
    _textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}