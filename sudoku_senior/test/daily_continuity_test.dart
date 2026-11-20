import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_zen/managers/game_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameStorage.resetCacheForTest();
  });

  test(
    'resuming yesterday daily preserves its date and awards only that stamp',
    () async {
      final state = GameState(
        board: List.filled(81, 0),
        initial: List.filled(81, 0),
        solution: List.filled(81, 1),
        notes: {},
        mistakes: 0,
        helpCount: 3,
        elapsedTime: 24,
        mode: 'daily',
        difficulty: 2,
        dailyDate: '2026-11-18',
      );
      await GameStorage.saveGameState(state);
      final restored = await GameStorage.loadGameState();
      expect(restored!.dailyDate, '2026-11-18');
      await GameStorage.markDailyCompleted(
        date: DateTime.parse(restored.dailyDate!),
      );
      expect(
        await GameStorage.isDailyCompletedToday(now: DateTime(2026, 11, 19)),
        isFalse,
      );
      await GameStorage.markDailyCompleted(
        date: DateTime.parse(restored.dailyDate!),
      );
      expect(await GameStorage.getDailyCompletedDates(), ['2026-11-18']);
    },
  );

  test('difficulty streak resets only on a loss at that level', () async {
    await GameStorage.recordDifficultyWin(
      difficulty: 2,
      elapsedSeconds: 120,
      mistakes: 0,
    );
    await GameStorage.recordDifficultyWin(
      difficulty: 2,
      elapsedSeconds: 100,
      mistakes: 1,
    );
    await GameStorage.recordDifficultyWin(
      difficulty: 3,
      elapsedSeconds: 180,
      mistakes: 0,
    );
    var stats = await GameStorage.getDifficultyStats(2);
    expect(stats.currentStreak, 2);
    expect(stats.cleanWinPercent, 50);
    expect(stats.bestTimeSeconds, 100);
    await GameStorage.recordDifficultyLoss(2);
    stats = await GameStorage.getDifficultyStats(2);
    expect(stats.currentStreak, 0);
    expect(stats.wins, 2);
    expect((await GameStorage.getDifficultyStats(3)).currentStreak, 1);
  });

  test('overlapping saves cannot resurrect a finished game', () async {
    final state = GameState(
      board: [0],
      initial: [0],
      solution: [1],
      notes: {},
      mistakes: 0,
      helpCount: 3,
      elapsedTime: 10,
      mode: 'daily',
      difficulty: 2,
      dailyDate: '2026-11-20',
    );
    await GameStorage.saveGameState(state);
    await Future.wait([
      GameStorage.saveGameState(state),
      GameStorage.clearGameState(),
    ]);
    expect(await GameStorage.loadGameState(), isNull);
  });

  test('save captures the board before asynchronous work begins', () async {
    final board = [0];
    final state = GameState(
      board: board,
      initial: [0],
      solution: [1],
      notes: {},
      mistakes: 0,
      helpCount: 3,
      elapsedTime: 10,
      mode: 'daily',
      difficulty: 2,
      dailyDate: '2026-11-20',
    );
    final pending = GameStorage.saveGameState(state);
    board[0] = 1;
    await pending;
    expect((await GameStorage.loadGameState())!.board, [0]);
  });

  test('concurrent daily completions retain both stamps', () async {
    await Future.wait([
      GameStorage.markDailyCompleted(date: DateTime(2026, 12, 31)),
      GameStorage.markDailyCompleted(date: DateTime(2027, 1, 1)),
    ]);
    expect(await GameStorage.getDailyCompletedDates(), [
      '2026-12-31',
      '2027-01-01',
    ]);
    expect(await GameStorage.getDailyStreak(now: DateTime(2027, 1, 1)), 2);
    expect(await GameStorage.getDailyStreak(now: DateTime(2027, 1, 2)), 2);
    expect(await GameStorage.getDailyStreak(now: DateTime(2027, 1, 3)), 0);
  });

  test('daily streak crosses leap day and month boundaries', () async {
    for (final day in [
      DateTime(2024, 2, 28),
      DateTime(2024, 2, 29),
      DateTime(2024, 3, 1),
    ]) {
      await GameStorage.markDailyCompleted(date: day);
    }
    expect(await GameStorage.getDailyStreak(now: DateTime(2024, 3, 1)), 3);
  });
}
