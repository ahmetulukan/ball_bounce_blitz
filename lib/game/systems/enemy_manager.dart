import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import '../components/enemy.dart';
import '../components/boss_enemy.dart';

/// Enemy management system that tracks active enemies,
/// handles enemy lifecycle, and provides statistics.
class EnemyManager extends Component with HasGameReference<BallBounceGame> {
  final List<Enemy> _activeEnemies = [];
  final List<BossEnemy> _activeBosses = [];
  
  int _totalSpawned = 0;
  int _totalDestroyed = 0;
  int _highestActiveCount = 0;

  /// Get all active enemies.
  List<Enemy> get activeEnemies => List.unmodifiable(_activeEnemies);
  
  /// Get all active bosses.
  List<BossEnemy> get activeBosses => List.unmodifiable(_activeBosses);
  
  /// Current enemy count.
  int get enemyCount => _activeEnemies.length;
  
  /// Current boss count.
  int get bossCount => _activeBosses.length;
  
  /// Total spawned count.
  int get totalSpawned => _totalSpawned;
  
  /// Total destroyed count.
  int get totalDestroyed => _totalDestroyed;

  /// Register a new enemy as active.
  void registerEnemy(Enemy enemy) {
    if (!_activeEnemies.contains(enemy)) {
      _activeEnemies.add(enemy);
      _totalSpawned++;
      _updateHighestCount();
    }
  }

  /// Unregister an enemy (destroyed or removed).
  void unregisterEnemy(Enemy enemy) {
    _activeEnemies.remove(enemy);
    _totalDestroyed++;
  }

  /// Register a new boss.
  void registerBoss(BossEnemy boss) {
    if (!_activeBosses.contains(boss)) {
      _activeBosses.add(boss);
      _totalSpawned++;
    }
  }

  /// Unregister a boss.
  void unregisterBoss(BossEnemy boss) {
    _activeBosses.remove(boss);
    _totalDestroyed++;
  }

  /// Get enemies within a certain radius of a position.
  List<Enemy> getEnemiesNear(Vector2 position, double radius) {
    return _activeEnemies.where((e) {
      return (e.position - position).length <= radius;
    }).toList();
  }

  /// Get the nearest enemy to a position.
  Enemy? getNearestEnemy(Vector2 position) {
    if (_activeEnemies.isEmpty) return null;
    
    Enemy? nearest;
    double minDist = double.infinity;
    
    for (final enemy in _activeEnemies) {
      final dist = (enemy.position - position).length;
      if (dist < minDist) {
        minDist = dist;
        nearest = enemy;
      }
    }
    return nearest;
  }

  /// Get count of enemies by type.
  Map<String, int> getEnemyCountsByType() {
    final counts = <String, int>{};
    for (final enemy in _activeEnemies) {
      final key = enemy.type.toString();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  /// Clear all tracked enemies (used on game reset).
  void clearAll() {
    _activeEnemies.clear();
    _activeBosses.clear();
    _totalSpawned = 0;
    _totalDestroyed = 0;
    _highestActiveCount = 0;
  }

  void _updateHighestCount() {
    final total = _activeEnemies.length + _activeBosses.length;
    if (total > _highestActiveCount) {
      _highestActiveCount = total;
    }
  }

  /// Get the highest active enemy count achieved this session.
  int get highestActiveCount => _highestActiveCount;

  /// Check if there are any active threats.
  bool get hasActiveThreats => 
      _activeEnemies.isNotEmpty || _activeBosses.isNotEmpty;
}

/// Extension to provide freeze factor to enemies
extension EnemyFreezeExtension on EnemyManager {
  double getFreezeFactor(BallBounceGame game) {
    return game.getFreezeFactor();
  }
}