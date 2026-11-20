import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_zen/managers/game_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameStorage.resetCacheForTest();
  });

  group('GameStorage - Reto del Día y Racha', () {
    test('persiste dailyCompletedDates, isDailyCompletedToday y calcula dailyStreak consecutivo', () async {
      final day1 = DateTime(2026, 11, 17);
      final day2 = DateTime(2026, 11, 18);
      final day3 = DateTime(2026, 11, 19);

      expect(await GameStorage.isDailyCompletedToday(now: day3), isFalse);
      expect(await GameStorage.getDailyStreak(now: day3), 0);

      await GameStorage.markDailyCompleted(date: day1);
      await GameStorage.markDailyCompleted(date: day2);

      // Si hoy (day3) aún no se completa pero ayer (day2) sí, la racha sigue activa en 2
      expect(await GameStorage.isDailyCompletedToday(now: day3), isFalse);
      expect(await GameStorage.getDailyStreak(now: day3), 2);

      // Al completar hoy (day3), sube a 3 y no duplica fechas
      final streakAfterToday = await GameStorage.markDailyCompleted(date: day3);
      await GameStorage.markDailyCompleted(date: day3);

      expect(streakAfterToday, 3);
      expect(await GameStorage.isDailyCompletedToday(now: day3), isTrue);
      expect(
        await GameStorage.getDailyCompletedDates(),
        equals(['2026-11-17', '2026-11-18', '2026-11-19']),
      );

      // Si pasa un día sin jugar (day5 = 21 nov), la racha se reinicia a 0
      final day5 = DateTime(2026, 11, 21);
      expect(await GameStorage.getDailyStreak(now: day5), 0);
    });
  });

  group('GameStorage - Estadísticas por dificultad', () {
    test('registra victorias, mejor tiempo, tiempo acumulado y victorias limpias por nivel 1..4', () async {
      // Nivel 1: 2 victorias (una limpia en 120s, otra con 1 error en 95s)
      await GameStorage.recordDifficultyWin(
        difficulty: 1,
        elapsedSeconds: 120,
        mistakes: 0,
      );
      await GameStorage.recordDifficultyWin(
        difficulty: 1,
        elapsedSeconds: 95,
        mistakes: 1,
      );

      // Nivel 3: 1 victoria limpia en 310s
      await GameStorage.recordDifficultyWin(
        difficulty: 3,
        elapsedSeconds: 310,
        mistakes: 0,
      );

      final all = await GameStorage.getAllDifficultyStats();
      expect(all.keys.toList(), equals([1, 2, 3, 4]));

      final level1 = all[1]!;
      expect(level1.wins, 2);
      expect(level1.bestTimeSeconds, 95);
      expect(level1.totalTimeSeconds, 215);
      expect(level1.cleanWins, 1);

      final level2 = all[2]!;
      expect(level2.wins, 0);
      expect(level2.bestTimeSeconds, isNull);
      expect(level2.totalTimeSeconds, 0);
      expect(level2.cleanWins, 0);

      final level3 = all[3]!;
      expect(level3.wins, 1);
      expect(level3.bestTimeSeconds, 310);
      expect(level3.totalTimeSeconds, 310);
      expect(level3.cleanWins, 1);

      final level4 = all[4]!;
      expect(level4.wins, 0);
    });
  });
}
