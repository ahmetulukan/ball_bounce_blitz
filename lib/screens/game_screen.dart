import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/game.dart';
import 'home_screen.dart';

class GameScreen extends StatelessWidget {
  GameScreen({super.key});

  final BallBounceBlitzGame game = BallBounceBlitzGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        backgroundBuilder: (_) => Container(color: Colors.black),
      ),
    );
  }
}