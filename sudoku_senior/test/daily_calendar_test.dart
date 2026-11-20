import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_zen/managers/game_storage.dart';
import 'package:sudoku_zen/widgets/daily_calendar.dart';

void main() {
  testWidgets(
    'calendar shows persisted stamps and returns from previous month',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      GameStorage.resetCacheForTest();
      final today = DateTime.now();
      await GameStorage.markDailyCompleted(date: today);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DailyCalendar())),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('${today.day}, reto completado'),
        findsOneWidget,
      );
      final nextButton = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Mes siguiente',
      );
      expect(tester.widget<IconButton>(nextButton).onPressed, isNull);
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('${today.day}, reto completado'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
