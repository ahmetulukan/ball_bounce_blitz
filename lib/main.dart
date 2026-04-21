import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  runApp(GameScreen());
}

class BallBounceBlitzApp extends StatelessWidget {
  const BallBounceBlitzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Bounce Blitz',
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}