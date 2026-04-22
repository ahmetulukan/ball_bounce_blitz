# Ball Bounce Blitz 🎮

Arcade reflex game built with Flutter & Flame engine.

## Features

- **Wave System** - Progressive difficulty across unlimited waves
- **6 Enemy Types** - Normal, Fast, Tough, Big, Shielded, Explosive
- **5 Power-ups** - Speed Boost ⚡, Shield 🛡️, Multi-Ball ✖3, Paddle Shrink 🔻, Magnet 🧲
- **Combo System** - Consecutive hits build combo multiplier
- **Particle Effects** - Score particles, explosion effects, ball trails
- **Screen Shake** - Impact feedback on hits and game over
- **Starfield Background** - Animated twinkling stars
- **Ball Trail** - Visual trail following the ball

## Running

```bash
cd ball_bounce_blitz
flutter run
```

## Controls

- **Drag** paddle left/right
- Collect power-ups falling from top
- Break all enemies - waves increase difficulty

## Project Structure

```
lib/
  main.dart
  game/
    game.dart          # FlameGame main class
    scene/game_scene.dart  # Core game logic
  components/
    ball.dart          # Ball physics + boost
    paddle.dart        # Draggable paddle
    enemy.dart         # 6 enemy types
    power_up.dart      # 5 power-up types
    combo_display.dart # Combo multiplier HUD
    wave_announcement.dart
    particle_effect.dart
    explosion_effect.dart
    screen_shake.dart
    starfield.dart
    ball_trail.dart
  screens/
    home_screen.dart
    game_screen.dart
    game_over_screen.dart
  services/
    audio_manager.dart
```

## Audio

Place audio files in `assets/audio/`:
- `hit.wav`, `score.wav`, `powerup.wav`, `gameover.wav`, `explosion.wav`