# Ball Bounce Blitz

🏓 **Ball Bounce Blitz** — Arcade action game built with Flutter and Flame engine.

A fast-paced brick-breaker style game where you control a paddle to bounce a ball and destroy enemies. Features power-ups, combos, boss waves, daily challenges, and achievements!

## Features

### Core Gameplay
- **Intuitive Controls**: Touch drag, keyboard (A/D, ←/→), or mouse
- **Wave System**: Progressive difficulty with enemy waves
- **Boss Battles**: Special boss enemies every 5 waves
- **Combo System**: Chain kills for score multipliers

### Power-Ups
- 🔥 **Fireball**: Ball burns enemies, increases speed
- 🛡️ **Shield**: Protective barrier around ball
- ⚡ **Laser**: Ball shoots lasers at enemies
- 🧲 **Magnet**: Attracts nearby power-ups
- 💥 **Explosive**: Destroys all nearby enemies
- ⏱️ **Slow-Mo**: Slows game time
- ❤️ **Extra Life**: Gain additional life
- 🔀 **Multiball**: Spawn extra balls

### Special Systems
- **Particle Effects**: Explosions, trails, sparks, confetti
- **Chain Lightning**: Fireball combos trigger lightning chains
- **Achievement System**: 10+ achievements to unlock
- **Daily Challenges**: Unique modifiers every day
- **High Score Tracking**: Local persistence with Hive

### Visual Effects
- Screen shake on impacts
- Shockwave rings on enemy destruction
- Floating score popups
- Combo flash effects
- Ghost trails for fast-moving balls

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── screens/                     # UI screens
│   ├── home_screen.dart
│   ├── game_screen.dart
│   ├── pause_screen.dart
│   ├── game_over_screen.dart
│   ├── settings_screen.dart
│   ├── achievements_screen.dart
│   └── daily_challenge_screen.dart
├── game/
│   ├── ball_bounce_game.dart     # Main game class
│   ├── components/               # Game components
│   │   ├── ball.dart
│   │   ├── paddle.dart
│   │   ├── enemy.dart
│   │   ├── boss_enemy.dart
│   │   ├── power_up.dart
│   │   ├── barrier.dart
│   │   ├── particles/
│   │   ├── chain_lightning.dart
│   │   ├── daily_challenge.dart
│   │   └── effects.dart
│   ├── systems/                  # Game systems
│   │   ├── spawn_system.dart
│   │   ├── combo_system.dart
│   │   ├── score_system.dart
│   │   └── enemy_manager.dart
│   ├── services/
│   │   ├── game_state_service.dart
│   │   └── settings_service.dart
│   └── ui/                       # UI overlays
│       ├── hud_overlay.dart
│       ├── main_menu_screen.dart
│       └── wave_announcement.dart
└── services/
    ├── audio_manager.dart
    └── achievement_service.dart
```

## Getting Started

### Prerequisites
- Flutter SDK 3.11+
- Dart 3.11+

### Installation

```bash
# Clone the repository
git clone https://github.com/ahmetulukan/ball_bounce_blitz.git
cd ball_bounce_blitz

# Get dependencies
flutter pub get

# Run the game
flutter run
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## Controls

| Input | Action |
|-------|--------|
| Mouse Drag / Touch | Move paddle |
| A / D or ← / → | Keyboard paddle control |
| ESC | Pause game |
| P | Pause game (alternative) |

## Audio

Place `.wav` files in `assets/audio/`:
- `bounce.wav` — Ball bounces off paddle
- `hit.wav` — Enemy destroyed
- `powerup.wav` — Power-up collected
- `score.wav` — Score gained
- `explosion.wav` — Large explosion
- `gameover.wav` — Game over
- `wave.wav` — New wave starts
- `lose.wav` — Life lost

## Game Mechanics

### Scoring
- Base enemy kill: 100 points
- Combo multiplier: +0.5x per chain (max 5x)
- Wave clear bonus: 500 × wave number
- Boss kill: 1000 points

### Lives System
- Start with 3 lives
- Lose 1 life when ball falls below screen
- Extra life power-up grants +1 life

### Difficulty Progression
- Wave 1-5: Basic enemies
- Wave 6-10: Faster enemies
- Wave 11+: Mixed enemy types
- Every 5th wave: Boss battle

## Tech Stack

- **Flutter**: UI framework
- **Flame**: Game engine
- **Flame Audio**: Sound effects
- **Hive**: Local data persistence
- **Shared Preferences**: Settings storage

## License

MIT License — See LICENSE file for details.

---

**Built with ❤️ using Flutter & Flame**