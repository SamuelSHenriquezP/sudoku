import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameState {
  final List<int> board;
  final List<int> initial;
  final List<int> solution;
  final Map<int, List<int>> notes;
  final int mistakes;
  final int helpCount;
  final int elapsedTime; // en segundos
  final String mode; // 'zen', 'reto' o 'aprendiz'
  final int difficulty;
  final int gridSize; // 9 (clásico) ó 4 (Modo Aprendiz)
  final String? dailyDate;

  GameState({
    required this.board,
    required this.initial,
    required this.solution,
    required this.notes,
    required this.mistakes,
    required this.helpCount,
    required this.elapsedTime,
    required this.mode,
    required this.difficulty,
    this.gridSize = 9,
    this.dailyDate,
  });

  Map<String, dynamic> toJson() => {
    'board': board,
    'initial': initial,
    'solution': solution,
    'notes': notes.map((k, v) => MapEntry(k.toString(), v)),
    'mistakes': mistakes,
    'helpCount': helpCount,
    'elapsedTime': elapsedTime,
    'mode': mode,
    'difficulty': difficulty,
    'gridSize': gridSize,
    'dailyDate': dailyDate,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> notesJson = json['notes'] ?? {};
    Map<int, List<int>> parsedNotes = {};
    notesJson.forEach((k, v) {
      parsedNotes[int.parse(k)] = List<int>.from(v);
    });

    return GameState(
      board: List<int>.from(json['board']),
      initial: List<int>.from(json['initial']),
      solution: List<int>.from(json['solution']),
      notes: parsedNotes,
      mistakes: json['mistakes'] ?? 0,
      helpCount: json['helpCount'] ?? 3,
      elapsedTime: json['elapsedTime'] ?? 0,
      mode: json['mode'] ?? 'reto',
      difficulty: json['difficulty'] ?? 1,
      gridSize: json['gridSize'] ?? 9,
      dailyDate: json['dailyDate'] as String?,
    );
  }
}

class DifficultyStats {
  final int difficulty; // 1: Principiante, 2: Normal, 3: Maestro, 4: Diabólico
  final int wins;
  final int? bestTimeSeconds;
  final int totalTimeSeconds;
  final int cleanWins;
  final int currentStreak;

  double get cleanWinPercent => wins == 0 ? 0 : cleanWins * 100 / wins;

  const DifficultyStats({
    required this.difficulty,
    this.wins = 0,
    this.bestTimeSeconds,
    this.totalTimeSeconds = 0,
    this.cleanWins = 0,
    this.currentStreak = 0,
  });

  int get averageTimeSeconds => wins > 0 ? totalTimeSeconds ~/ wins : 0;
}

class GameStorage {
  static const String _keyState = 'current_game_state';
  static const String _keyStateBackup = 'current_game_state_backup';
  static const String _keyStatsRetoWon = 'stats_reto_won';
  static const String _keyStatsRetoPlayed = 'stats_reto_played';
  static const String _keyStatsMaestroWon = 'stats_maestro_won';
  static const String _keyTutorialSeen = 'tutorial_seen';
  static const String _keyUnlockedQuotes = 'unlocked_quotes';
  static const String _keyDailyCompletedDates = 'daily_completed_dates';
  static const String _keyDailyStreak = 'daily_streak';
  // Se desbloquea Diabólico tras ganar 10 partidas en Modo Reto Maestro
  static const int _diabolicoUnlockThreshold = 10;

  static SharedPreferences? _cachedPrefs;
  static Future<void> _pendingStateWrites = Future.value();

  static Future<void> _queueStateWrite(Future<void> Function() action) {
    final result = _pendingStateWrites.then((_) => action());
    _pendingStateWrites = result.catchError(
      (Object error, StackTrace stack) {},
    );
    return result;
  }

  static Future<SharedPreferences> _getPrefs() async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  /// Limpia la caché de preferencias (útil en pruebas unitarias).
  static void resetCacheForTest() {
    _cachedPrefs = null;
  }

  static Future<void> saveGameState(GameState state) {
    // Freeze mutable board/notes before the first await.
    final encoded = jsonEncode(state.toJson());
    return _queueStateWrite(() async {
      try {
        final prefs = await _getPrefs();
        final existing = prefs.getString(_keyState);
        if (existing != null && existing.isNotEmpty) {
          await prefs.setString(_keyStateBackup, existing);
        }
        await prefs.setString(_keyState, encoded);
      } catch (_) {}
    });
  }

  // --- Tutorial ---
  static Future<bool> hasTutorialSeen() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyTutorialSeen) ?? false;
  }

  static Future<void> setTutorialSeen() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyTutorialSeen, true);
  }

  // --- Quotes / Recompensas ---
  static Future<List<int>> getUnlockedQuotes() async {
    final prefs = await _getPrefs();
    final List<String> list = prefs.getStringList(_keyUnlockedQuotes) ?? [];
    return list
        .map((e) => int.tryParse(e))
        .where((e) => e != null)
        .cast<int>()
        .toList();
  }

  static Future<void> unlockQuote(int id) async {
    final prefs = await _getPrefs();
    List<String> list = prefs.getStringList(_keyUnlockedQuotes) ?? [];
    if (!list.contains(id.toString())) {
      list.add(id.toString());
      await prefs.setStringList(_keyUnlockedQuotes, list);
    }
  }

  static Future<GameState?> loadGameState() async {
    await _pendingStateWrites;
    final prefs = await _getPrefs();
    final data = prefs.getString(_keyState);
    if (data != null && data.isNotEmpty) {
      try {
        return GameState.fromJson(jsonDecode(data));
      } catch (e) {
        // Main state corrupted, try backup
      }
    }

    final backup = prefs.getString(_keyStateBackup);
    if (backup != null && backup.isNotEmpty) {
      try {
        return GameState.fromJson(jsonDecode(backup));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearGameState() => _queueStateWrite(() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyState);
    await prefs.remove(_keyStateBackup);
  });

  static Future<void> incrementRetoPlayed() async {
    final prefs = await _getPrefs();
    int current = prefs.getInt(_keyStatsRetoPlayed) ?? 0;
    await prefs.setInt(_keyStatsRetoPlayed, current + 1);
  }

  static Future<void> incrementRetoWon({int difficulty = 1}) async {
    final prefs = await _getPrefs();
    int current = prefs.getInt(_keyStatsRetoWon) ?? 0;
    await prefs.setInt(_keyStatsRetoWon, current + 1);
    // Contabilizar si fue una victoria en Maestro (dificultad 3)
    if (difficulty == 3) {
      int maestroWon = prefs.getInt(_keyStatsMaestroWon) ?? 0;
      await prefs.setInt(_keyStatsMaestroWon, maestroWon + 1);
    }
  }

  static Future<bool> isDiabolicoUnlocked() async {
    final prefs = await _getPrefs();
    int maestroWon = prefs.getInt(_keyStatsMaestroWon) ?? 0;
    return maestroWon >= _diabolicoUnlockThreshold;
  }

  static Future<int> getMaestroWins() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyStatsMaestroWon) ?? 0;
  }

  static Future<Map<String, int>> getStats() async {
    final prefs = await _getPrefs();
    return {
      'played': prefs.getInt(_keyStatsRetoPlayed) ?? 0,
      'won': prefs.getInt(_keyStatsRetoWon) ?? 0,
      'maestroWon': prefs.getInt(_keyStatsMaestroWon) ?? 0,
    };
  }

  // --- Reto del Día y racha diaria ---
  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<List<String>> getDailyCompletedDates() async {
    final prefs = await _getPrefs();
    final list = List<String>.from(
      prefs.getStringList(_keyDailyCompletedDates) ?? const [],
    );
    list.sort();
    return list;
  }

  static Future<bool> isDailyCompletedToday({DateTime? now}) async {
    final todayKey = formatDateKey(now ?? DateTime.now());
    final dates = await getDailyCompletedDates();
    return dates.contains(todayKey);
  }

  static int _computeDailyStreak(
    Set<String> completedDates,
    DateTime reference,
  ) {
    final today = DateTime(reference.year, reference.month, reference.day);
    final todayKey = formatDateKey(today);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayKey = formatDateKey(yesterday);

    DateTime cursor;
    if (completedDates.contains(todayKey)) {
      cursor = today;
    } else if (completedDates.contains(yesterdayKey)) {
      cursor = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (completedDates.contains(formatDateKey(cursor))) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  static Future<int> getDailyStreak({DateTime? now}) async {
    final dates = await getDailyCompletedDates();
    final streak = _computeDailyStreak(dates.toSet(), now ?? DateTime.now());
    final prefs = await _getPrefs();
    await prefs.setInt(_keyDailyStreak, streak);
    return streak;
  }

  static Future<int> markDailyCompleted({DateTime? date}) async {
    final target = date ?? DateTime.now();
    final key = formatDateKey(target);
    final prefs = await _getPrefs();
    final dates = List<String>.from(
      prefs.getStringList(_keyDailyCompletedDates) ?? const [],
    );
    if (!dates.contains(key)) {
      dates.add(key);
      dates.sort();
      await prefs.setStringList(_keyDailyCompletedDates, dates);
    }
    final streak = _computeDailyStreak(dates.toSet(), target);
    await prefs.setInt(_keyDailyStreak, streak);
    return streak;
  }

  // --- Estadísticas por dificultad (1..4) ---
  static Future<void> recordDifficultyWin({
    required int difficulty,
    required int elapsedSeconds,
    required int mistakes,
  }) async {
    if (difficulty < 1 || difficulty > 4) return;
    final prefs = await _getPrefs();
    final winsKey = 'stats_diff_${difficulty}_wins';
    final bestKey = 'stats_diff_${difficulty}_best_time';
    final totalKey = 'stats_diff_${difficulty}_total_time';
    final cleanKey = 'stats_diff_${difficulty}_clean_wins';

    final wins = (prefs.getInt(winsKey) ?? 0) + 1;
    await prefs.setInt(winsKey, wins);
    final streakKey = 'stats_diff_${difficulty}_streak';
    await prefs.setInt(streakKey, (prefs.getInt(streakKey) ?? 0) + 1);

    final safeElapsed = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    final totalTime = (prefs.getInt(totalKey) ?? 0) + safeElapsed;
    await prefs.setInt(totalKey, totalTime);

    final prevBest = prefs.getInt(bestKey);
    if (prevBest == null || safeElapsed < prevBest) {
      await prefs.setInt(bestKey, safeElapsed);
    }

    if (mistakes == 0) {
      final cleanWins = (prefs.getInt(cleanKey) ?? 0) + 1;
      await prefs.setInt(cleanKey, cleanWins);
    }
  }

  static Future<void> recordDifficultyLoss(int difficulty) async {
    if (difficulty < 1 || difficulty > 4) return;
    final prefs = await _getPrefs();
    await prefs.setInt('stats_diff_${difficulty}_streak', 0);
  }

  static Future<DifficultyStats> getDifficultyStats(int difficulty) async {
    final prefs = await _getPrefs();
    return DifficultyStats(
      difficulty: difficulty,
      wins: prefs.getInt('stats_diff_${difficulty}_wins') ?? 0,
      bestTimeSeconds: prefs.getInt('stats_diff_${difficulty}_best_time'),
      totalTimeSeconds:
          prefs.getInt('stats_diff_${difficulty}_total_time') ?? 0,
      cleanWins: prefs.getInt('stats_diff_${difficulty}_clean_wins') ?? 0,
      currentStreak: prefs.getInt('stats_diff_${difficulty}_streak') ?? 0,
    );
  }

  static Future<Map<int, DifficultyStats>> getAllDifficultyStats() async {
    final result = <int, DifficultyStats>{};
    for (int d = 1; d <= 4; d++) {
      result[d] = await getDifficultyStats(d);
    }
    return result;
  }
}
