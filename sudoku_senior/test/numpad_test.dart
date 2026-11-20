import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_zen/widgets/numpad.dart';

void main() {
  testWidgets('NumPad muestra faltantes y deshabilita dígitos completados', (tester) async {
    final tapped = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumPad(
            isPencilMode: false,
            onTogglePencil: () {},
            onNumberInput: tapped.add,
            onErase: () {},
            onHelp: () {},
            onUndo: () {},
            completedNumbers: const {1},
            numberCounts: const {
              1: 9,
              2: 7,
              3: 0,
              4: 0,
              5: 0,
              6: 0,
              7: 0,
              8: 0,
              9: 0,
            },
          ),
        ),
      ),
    );

    // El dígito 1 está completado: tiene ícono check y no dispara onNumberInput
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('1'));
    expect(tapped, isEmpty);

    // El dígito 2 muestra 2 faltantes (9 - 7 = 2) y sí dispara onNumberInput
    expect(find.text('2'), findsNWidgets(2));
    await tester.tap(find.text('2').first);
    expect(tapped, equals([2]));
  });
}
