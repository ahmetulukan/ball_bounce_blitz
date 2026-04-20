import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

class HudWidget extends StatefulWidget {
  final BallBounceGame game;
  const HudWidget({super.key, required this.game});

  @override
  State<HudWidget> createState() => _HudWidgetState();
}

class _HudWidgetState extends State<HudWidget> {
  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {});
        return !widget.game.isGameOver;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBox('SCORE: ${game.score}', Colors.black54),
            _buildBox('WAVE ${game.wave}', Colors.deepPurple.withAlpha(200)),
            Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.favorite,
                  color: i < game.lives ? Colors.red : Colors.grey,
                  size: 22,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
