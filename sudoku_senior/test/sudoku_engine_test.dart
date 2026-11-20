import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_zen/engine/sudoku_engine.dart';

void main() {
  group('SudokuEngine (9x9)', () {
    test(
      'genera una solución 9x9 válida sin números repetidos en filas, columnas ni cajas',
      () {
        final engine = SudokuEngine();
        engine.generate(1);

        expect(engine.solution.length, 81);
        expect(engine.solution.contains(0), isFalse);

        // Validar filas
        for (int r = 0; r < 9; r++) {
          final row = [for (int c = 0; c < 9; c++) engine.solution[r * 9 + c]];
          expect(
            row.toSet().length,
            9,
            reason: 'Fila $r tiene números duplicados',
          );
          expect(row.every((n) => n >= 1 && n <= 9), isTrue);
        }

        // Validar columnas
        for (int c = 0; c < 9; c++) {
          final col = [for (int r = 0; r < 9; r++) engine.solution[r * 9 + c]];
          expect(
            col.toSet().length,
            9,
            reason: 'Columna $c tiene números duplicados',
          );
          expect(col.every((n) => n >= 1 && n <= 9), isTrue);
        }

        // Validar cajas 3x3
        for (int br = 0; br < 3; br++) {
          for (int bc = 0; bc < 3; bc++) {
            final box = <int>[];
            for (int r = 0; r < 3; r++) {
              for (int c = 0; c < 3; c++) {
                box.add(engine.solution[(br * 3 + r) * 9 + (bc * 3 + c)]);
              }
            }
            expect(
              box.toSet().length,
              9,
              reason: 'Caja ($br, $bc) tiene números duplicados',
            );
          }
        }
      },
    );

    test('el puzzle es un subconjunto coherente de la solución', () {
      final engine = SudokuEngine();
      engine.generate(2);

      expect(engine.puzzle.length, 81);
      int clues = 0;
      for (int i = 0; i < 81; i++) {
        if (engine.puzzle[i] != 0) {
          clues++;
          expect(
            engine.puzzle[i],
            engine.solution[i],
            reason: 'La pista en $i no coincide con la solución',
          );
        }
      }
      expect(clues, greaterThan(20));
      expect(clues, lessThan(50));
    });

    test('generateAsync ejecuta correctamente mediante Isolate.run', () async {
      final generated = await SudokuEngine.generateAsync(1);
      expect(generated.solution.length, 81);
      expect(generated.puzzle.length, 81);
      expect(generated.puzzle.contains(0), isTrue);
    });

    test('generateDailyPuzzle es determinista por fecha', () {
      final dateMorning = DateTime(2026, 11, 19, 8, 15);
      final dateNight = DateTime(2026, 11, 19, 22, 45);
      final nextDay = DateTime(2026, 11, 20, 8, 15);

      final first = SudokuEngine.generateDailyPuzzle(dateMorning);
      final second = SudokuEngine.generateDailyPuzzle(dateNight);
      final different = SudokuEngine.generateDailyPuzzle(nextDay);

      expect(first.solution, equals(second.solution));
      expect(first.puzzle, equals(second.puzzle));
      expect(first.puzzle, isNot(equals(different.puzzle)));

      // Verificar validez del tablero diario
      expect(first.solution.length, 81);
      expect(first.solution.contains(0), isFalse);
      for (int i = 0; i < 81; i++) {
        if (first.puzzle[i] != 0) {
          expect(first.puzzle[i], first.solution[i]);
        }
      }
    });

    test(
      'cleanPeerNotes limpia fila, columna y bloque 3x3 sin afectar otras celdas',
      () {
        // Celda 10 => fila 1, columna 1, bloque superior izquierdo (0..2, 0..2)
        final notes = <int, List<int>>{
          12: [5, 7], // Misma fila (r=1, c=3) -> debe quitar 5, dejar [7]
          28: [5], // Misma columna (r=3, c=1) -> debe quitar 5 y borrar entrada
          20: [
            2,
            5,
            9,
          ], // Mismo bloque 3x3 (r=2, c=2) -> debe quitar 5, dejar [2, 9]
          40: [5, 8], // Celda ajena (r=4, c=4) -> debe conservar [5, 8]
        };

        SudokuEngine.cleanPeerNotes(notes, 10, 5, gridSize: 9);

        expect(notes[12], equals([7]));
        expect(notes.containsKey(28), isFalse);
        expect(notes[20], equals([2, 9]));
        expect(notes[40], equals([5, 8]));
      },
    );

    test(
      'calculateNumberCounts cuenta solo dígitos válidos que coinciden con la solución',
      () {
        final engine = SudokuEngine();
        engine.generate(1);

        final board = List<int>.filled(81, 0);
        // Colocar todas las 9 apariciones correctas del dígito 1
        int placedOnes = 0;
        for (int i = 0; i < 81; i++) {
          if (engine.solution[i] == 1) {
            board[i] = 1;
            placedOnes++;
          }
        }
        // Colocar 2 apariciones correctas y 1 incorrecta del dígito 2
        int placedTwos = 0;
        for (int i = 0; i < 81; i++) {
          if (engine.solution[i] == 2 && placedTwos < 2) {
            board[i] = 2;
            placedTwos++;
          }
        }
        final incorrectIndex = List.generate(
          81,
          (i) => i,
        ).firstWhere((i) => board[i] == 0 && engine.solution[i] != 2);
        board[incorrectIndex] = 2;

        final counts = SudokuEngine.calculateNumberCounts(
          board,
          engine.solution,
        );
        expect(placedOnes, 9);
        expect(counts[1], 9);
        expect(counts[2], 2);
        expect(counts[3], 0);
      },
    );
  });

  group('SudokuEngine4x4 (Modo Aprendiz)', () {
    test('genera una solución 4x4 válida con dígitos 1-4', () {
      final engine = SudokuEngine4x4();
      engine.generate();

      expect(engine.solution.length, 16);
      expect(engine.solution.contains(0), isFalse);

      // Filas
      for (int r = 0; r < 4; r++) {
        final row = [for (int c = 0; c < 4; c++) engine.solution[r * 4 + c]];
        expect(row.toSet().length, 4, reason: 'Fila $r inválida');
        expect(row.every((n) => n >= 1 && n <= 4), isTrue);
      }

      // Columnas
      for (int c = 0; c < 4; c++) {
        final col = [for (int r = 0; r < 4; r++) engine.solution[r * 4 + c]];
        expect(col.toSet().length, 4, reason: 'Columna $c inválida');
      }

      // Cajas 2x2
      for (int br = 0; br < 2; br++) {
        for (int bc = 0; bc < 2; bc++) {
          final box = <int>[];
          for (int r = 0; r < 2; r++) {
            for (int c = 0; c < 2; c++) {
              box.add(engine.solution[(br * 2 + r) * 4 + (bc * 2 + c)]);
            }
          }
          expect(box.toSet().length, 4, reason: 'Caja 2x2 ($br, $bc) inválida');
        }
      }
    });

    test(
      'generateAsync 4x4 ejecuta correctamente mediante Isolate.run',
      () async {
        final generated = await SudokuEngine4x4.generateAsync();
        expect(generated.solution.length, 16);
        expect(generated.puzzle.length, 16);
        expect(generated.puzzle.contains(0), isTrue);
      },
    );
  });
}
