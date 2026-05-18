import 'package:flutter/material.dart';
import '../game/ball_bounce_game.dart';
import '../game/systems/tournament_system.dart';

class TournamentScreen extends StatefulWidget {
  final BallBounceGame game;

  const TournamentScreen({super.key, required this.game});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  late TournamentManager _tournament;
  bool _matchStarted = false;
  int _playerScore = 0;

  @override
  void initState() {
    super.initState();
    _tournament = widget.game.tournamentManager;
  }

  void _startTournament() {
    setState(() {
      _tournament.startTournament();
      _matchStarted = false;
    });
  }

  void _startMatch() {
    if (_tournament.state == TournamentState.completed) {
      _showFinalResults();
      return;
    }

    // Reset game state for match
    widget.game.resetGame();
    widget.game.startGame();
    setState(() {
      _matchStarted = true;
    });
  }

  void _onMatchComplete() {
    _playerScore = widget.game.score;
    final playerWave = widget.game.wave;
    _tournament.onMatchComplete(_playerScore, playerWave);

    setState(() {
      _matchStarted = false;
    });

    if (_tournament.state == TournamentState.completed) {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
    final winner = _tournament.bracket.isNotEmpty ? _tournament.bracket.first : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          winner?.isWinner == true ? '🏆 CHAMPION!' : 'Tournament Ended',
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (winner != null) ...[
              const Text('👑', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 8),
              Text(winner.name, style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 4),
              Text('Score: ${winner.score}', style: const TextStyle(color: Colors.white70)),
              Text('Wave: ${winner.wave}', style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 16),
            _buildStreakDisplay(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startTournament();
            },
            child: const Text('🔄 Play Again', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.game.overlays.remove('Tournament');
            },
            child: const Text('← Exit', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF5722).withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tournament.streakEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_tournament.dailyStreak} Day Streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('x${_tournament.streakMultiplier} multiplier', style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _tournament.state;
    final bracket = _tournament.bracket;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF00BCD4),
        title: const Text('🏆 Tournament'),
        leading: IconButton(
          icon: const Text('←', style: TextStyle(fontSize: 24)),
          onPressed: () => widget.game.overlays.remove('Tournament'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_tournament.streakEmoji, style: const TextStyle(fontSize: 20))),
          ),
        ],
      ),
      body: _matchStarted
          ? _buildMatchView()
          : _buildBracketView(state, bracket),
    );
  }

  Widget _buildMatchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '⚔️ MATCH IN PROGRESS',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Round: ${_tournament.currentRoundName}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Score: ${widget.game.score} | Wave: ${widget.game.wave}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _onMatchComplete,
            child: const Text('⚠️ Simulate Match End (Test)', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketView(TournamentState state, List<TournamentEntry> bracket) {
    if (state == TournamentState.notStarted) {
      return _buildStartScreen();
    }

    return Column(
      children: [
        // Round indicator
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1A2E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _roundChip('Quarter', _tournament.currentRound == TournamentRound.quarter),
              const Text('→', style: TextStyle(color: Colors.white54)),
              _roundChip('Semi', _tournament.currentRound == TournamentRound.semi),
              const Text('→', style: TextStyle(color: Colors.white54)),
              _roundChip('Final', _tournament.currentRound == TournamentRound.final_),
            ],
          ),
        ),
        // Bracket
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildBracketGrid(bracket),
          ),
        ),
        // Action button
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildActionButton(),
        ),
      ],
    );
  }

  Widget _roundChip(String name, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF9C27B0) : Colors.grey.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: active ? Colors.white : Colors.white54,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBracketGrid(List<TournamentEntry> bracket) {
    if (bracket.isEmpty) return const SizedBox();

    final rounds = _tournament.currentRound == TournamentRound.quarter
        ? 3
        : _tournament.currentRound == TournamentRound.semi ? 2 : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Quarter final
        if (_tournament.currentRound == TournamentRound.quarter)
          _buildRoundColumn(bracket.take(8).toList(), 'Q-Finals', 4),
        // Semi final
        if (_tournament.currentRound == TournamentRound.semi ||
           _tournament.currentRound == TournamentRound.final_)
          _buildRoundColumn(bracket.take(4).toList(), 'Semi', 2),
        // Final
        if (_tournament.currentRound == TournamentRound.final_)
          _buildRoundColumn(bracket.take(2).toList(), 'Final', 1),
      ],
    );
  }

  Widget _buildRoundColumn(List<TournamentEntry> entries, String name, int matchCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(name, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 8),
          ...List.generate(matchCount * 2, (i) {
            if (i >= entries.length) {
              return Container(height: 40, width: 100, margin: const EdgeInsets.symmetric(vertical: 4));
            }
            return _buildBracketEntry(entries[i]);
          }),
        ],
      ),
    );
  }

  Widget _buildBracketEntry(TournamentEntry entry) {
    Color bgColor = const Color(0xFF2A2A4E);
    if (entry.isEliminated) bgColor = Colors.grey.withAlpha(40);
    if (entry.isWinner) bgColor = const Color(0xFF4A3A1E);

    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.isWinner
              ? const Color(0xFFFFD700)
              : entry.isEliminated
                  ? Colors.grey.withAlpha(80)
                  : const Color(0xFF00BCD4).withAlpha(80),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${entry.seed}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text(entry.name.length > 8 ? entry.name.substring(0, 8) : entry.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!entry.isEliminated && entry.score > 0)
            Text('${entry.score}pts', style: const TextStyle(color: Colors.white54, fontSize: 9)),
          if (entry.isEliminated)
            const Text('❌', style: TextStyle(fontSize: 12)),
          if (entry.isWinner)
            const Text('👑', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          const Text(
            'TOURNAMENT MODE',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '8-player bracket competition',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildStreakDisplay(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startTournament,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('START TOURNAMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_tournament.state == TournamentState.completed) {
      return ElevatedButton(
        onPressed: _startTournament,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
        ),
        child: const Text('🔄 Play Again'),
      );
    }

    final currentMatch = _tournament.currentRoundMatches;
    if (currentMatch.isEmpty) return const SizedBox();

    return ElevatedButton(
      onPressed: _startMatch,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      child: Text(
        '⚔️ Play Match (vs ${currentMatch.length > 1 ? currentMatch[1].name : "?"})',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}