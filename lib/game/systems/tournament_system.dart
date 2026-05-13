import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import 'package:flutter/material.dart' show Colors, TextPainter, TextSpan, TextStyle, TextDirection, Offset, FontWeight, Rect, Radius, RRect, PaintingStyle;

/// Tournament mode - competitive brackets with AI opponents
enum TournamentState { notStarted, inProgress, completed }
enum TournamentRound { quarter, semi, final_ }

class TournamentEntry {
  final String name;
  final int seed;
  int score = 0;
  int wave = 0;
  bool isEliminated = false;
  bool isWinner = false;

  TournamentEntry({required this.name, required this.seed});
}

class TournamentManager extends Component {
  late BallBounceGame gameRef;

  TournamentState state = TournamentState.notStarted;
  TournamentRound currentRound = TournamentRound.quarter;
  final List<TournamentEntry> bracket = [];
  int currentMatchIndex = 0;
  int roundMatchesCompleted = 0;
  int totalRoundMatches = 4; // quarter final = 4 matches
  double roundTimer = 0;
  static const double matchDuration = 45.0; // seconds per match

  // Streak tracking
  int dailyStreak = 0;
  DateTime? lastPlayDate;

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  void startTournament() {
    if (bracket.length < 8) {
      _generateBracket();
    }
    state = TournamentState.inProgress;
    currentMatchIndex = 0;
    roundMatchesCompleted = 0;
    currentRound = TournamentRound.quarter;
    totalRoundMatches = 4;
    roundTimer = 0;
  }

  void _generateBracket() {
    bracket.clear();
    final names = ['Player', 'Bot Alpha', 'Bot Beta', 'Bot Gamma',
                  'Bot Delta', 'Bot Epsilon', 'Bot Zeta', 'Bot Eta'];
    final random = Random();

    // Shuffle with seed for variety
    final shuffled = List<String>.from(names)..shuffle(random);
    for (int i = 0; i < 8; i++) {
      bracket.add(TournamentEntry(name: shuffled[i], seed: i + 1));
    }
  }

  TournamentEntry? get currentPlayer {
    return bracket.isNotEmpty ? bracket.first : null;
  }

  List<TournamentEntry> get currentRoundMatches {
    final start = currentMatchIndex;
    final end = (start + 2).clamp(0, bracket.length);
    if (start >= bracket.length) return [];
    return bracket.sublist(start, end);
  }

  void onMatchComplete(int playerScore, int playerWave) {
    if (bracket.isEmpty || currentMatchIndex >= bracket.length) return;

    final player = bracket[0];
    player.score = playerScore;
    player.wave = playerWave;

    // Determine if player won this match
    final opponent = bracket[currentMatchIndex + 1];
    opponent.score = playerScore - 100 - Random().nextInt(200);
    opponent.wave = (playerWave * 0.8).round();

    if (playerScore > opponent.score) {
      opponent.isEliminated = true;
    } else {
      player.isEliminated = true;
      // Player eliminated - tournament over
    }

    roundMatchesCompleted++;
    currentMatchIndex += 2;

    if (roundMatchesCompleted >= totalRoundMatches) {
      _advanceRound();
    }
  }

  void _advanceRound() {
    roundMatchesCompleted = 0;
    currentMatchIndex = 0;

    // Remove eliminated players
    bracket.removeWhere((e) => e.isEliminated);

    if (bracket.length <= 2) {
      state = TournamentState.completed;
      if (bracket.isNotEmpty && !bracket.first.isEliminated) {
        bracket.first.isWinner = true;
      }
      return;
    }

    if (currentRound == TournamentRound.quarter) {
      currentRound = TournamentRound.semi;
      totalRoundMatches = 2;
    } else if (currentRound == TournamentRound.semi) {
      currentRound = TournamentRound.final_;
      totalRoundMatches = 1;
    }
  }

  String get currentRoundName {
    switch (currentRound) {
      case TournamentRound.quarter: return 'Quarter Finals';
      case TournamentRound.semi: return 'Semi Finals';
      case TournamentRound.final_: return 'FINAL';
    }
  }

  void reset() {
    state = TournamentState.notStarted;
    bracket.clear();
    currentMatchIndex = 0;
    roundMatchesCompleted = 0;
    roundTimer = 0;
  }

  // Daily streak management
  Future<void> checkDailyStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastPlayDate != null) {
      final last = DateTime(lastPlayDate!.year, lastPlayDate!.month, lastPlayDate!.day);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        dailyStreak++;
      } else if (diff > 1) {
        dailyStreak = 1;
      }
    } else {
      dailyStreak = 1;
    }
    lastPlayDate = today;
  }

  int get streakMultiplier => (dailyStreak.clamp(1, 7));

  String get streakEmoji {
    if (dailyStreak >= 7) return '🔥🔥🔥';
    if (dailyStreak >= 5) return '🔥🔥';
    if (dailyStreak >= 3) return '🔥';
    return '⭐';
  }
}

/// Tournament bracket UI component
class TournamentBracketDisplay extends PositionComponent {
  late BallBounceGame gameRef;
  double _phase = 0;

  TournamentBracketDisplay({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    final tm = gameRef.tournamentManager;

    // Background panel
    final bgPaint = Paint()..color = const Color(0xFF1A1A2E).withAlpha(230);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 180, 200),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    // Border glow
    final borderPaint = Paint()
      ..color = const Color(0xFF9C27B0).withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 180, 200),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    // Round name
    _drawText(canvas, tm.currentRoundName, 12, const Color(0xFF9C27B0), 8, 8);

    // Bracket visualization
    _drawBracketRound(canvas, tm.bracket, 15, 40, 40);
  }

  void _drawText(Canvas canvas, String text, double fontSize, Color color, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x, y));
  }

  void _drawBracketRound(Canvas canvas, List<TournamentEntry> entries, double x, double y, double spacing) {
    for (int i = 0; i < entries.length && i < 8; i++) {
      final entry = entries[i];
      final entryY = y + (i ~/ 2) * spacing + (i % 2) * 20;

      Color nameColor = Colors.white;
      if (entry.isEliminated) nameColor = Colors.grey;
      if (entry.isWinner) nameColor = const Color(0xFFFFD700);

      final name = entry.name.length > 10 ? entry.name.substring(0, 10) : entry.name;
      _drawText(canvas, '#${entry.seed} $name', 9, nameColor, x, entryY);

      if (entry.isEliminated) {
        _drawText(canvas, '❌', 9, Colors.red, x + 60, entryY);
      } else if (entry.isWinner) {
        _drawText(canvas, '👑', 9, const Color(0xFFFFD700), x + 60, entryY);
      }
    }
  }
}