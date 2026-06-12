import 'package:flutter_test/flutter_test.dart';
import 'package:texnik_ijodkorlik/features/topic/stages/crossword_solver.dart';
import 'package:texnik_ijodkorlik/data/models/models.dart';

const _simple = [
  CrosswordClue(orientation: 'Gorizontal', clue: 'Test 1', answer: 'APPLE'),
  CrosswordClue(orientation: 'Vertikal',   clue: 'Test 2', answer: 'APRICOT'),
  CrosswordClue(orientation: 'Gorizontal', clue: 'Test 3', answer: 'CACTUS'),
];

const _apostrophe = [
  CrosswordClue(orientation: 'Gorizontal', clue: 'Test', answer: "TA'LIM"),
];

void main() {
  group('PlacedWord', () {
    test('normalizes apostrophe in answer', () {
      const clue = CrosswordClue(orientation: 'Gorizontal', clue: 'x', answer: "TA'LIM");
      const w = PlacedWord(number: 1, clue: clue, row: 0, col: 0, isHorizontal: true);
      expect(w.answer, 'TALIM');
      expect(w.length, 5);
    });

    test('cells maps correctly for horizontal word', () {
      const clue = CrosswordClue(orientation: 'Gorizontal', clue: 'x', answer: 'ABC');
      const w = PlacedWord(number: 1, clue: clue, row: 2, col: 3, isHorizontal: true);
      expect(w.cells, {(2, 3): 'A', (2, 4): 'B', (2, 5): 'C'});
    });

    test('cells maps correctly for vertical word', () {
      const clue = CrosswordClue(orientation: 'Vertikal', clue: 'x', answer: 'ABC');
      const w = PlacedWord(number: 1, clue: clue, row: 1, col: 4, isHorizontal: false);
      expect(w.cells, {(1, 4): 'A', (2, 4): 'B', (3, 4): 'C'});
    });
  });

  group('CrosswordSolver', () {
    test('returns empty for empty input', () {
      expect(CrosswordSolver.solve([]), isEmpty);
    });

    test('places all words', () {
      final placed = CrosswordSolver.solve(_simple);
      expect(placed.length, _simple.length);
    });

    test('no letter conflicts in resulting grid', () {
      final placed = CrosswordSolver.solve(_simple);
      final grid = <(int, int), String>{};
      for (final word in placed) {
        word.cells.forEach((pos, letter) {
          if (grid.containsKey(pos)) {
            expect(grid[pos], letter,
                reason: 'Letter conflict at row=${pos.$1} col=${pos.$2}');
          }
          grid[pos] = letter;
        });
      }
    });

    test('all words have positive clue number', () {
      final placed = CrosswordSolver.solve(_simple);
      for (final w in placed) {
        expect(w.number, greaterThan(0));
      }
    });

    test('all clue numbers are unique', () {
      final placed = CrosswordSolver.solve(_simple);
      final nums = placed.map((w) => w.number).toSet();
      expect(nums.length, placed.length);
    });

    test('handles apostrophe in answer', () {
      final placed = CrosswordSolver.solve(_apostrophe);
      expect(placed.first.answer, 'TALIM');
    });

    test('places topic-1 clues without conflicts', () {
      final topic1 = [
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c1', answer: 'RIVOJLANISH'),
        const CrosswordClue(orientation: 'Vertikal',   clue: 'c2', answer: 'INNOVATSIYA'),
        const CrosswordClue(orientation: 'Vertikal',   clue: 'c3', answer: 'TEXNOLOGIYA'),
        const CrosswordClue(orientation: 'Vertikal',   clue: 'c4', answer: 'IQTISODIYOT'),
        const CrosswordClue(orientation: 'Vertikal',   clue: 'c5', answer: 'IJODKORLIK'),
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c6', answer: 'KONSEPSIYA'),
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c7', answer: 'STRATEGIYA'),
        const CrosswordClue(orientation: 'Vertikal',   clue: 'c8', answer: 'HAMKORLIK'),
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c9', answer: 'TAFAKKUR'),
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c10', answer: 'AMALIYOT'),
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c11', answer: 'QURILMA'),
        const CrosswordClue(orientation: 'Vertikal',   clue: 'c12', answer: 'JAMIYAT'),
        const CrosswordClue(orientation: 'Gorizontal', clue: 'c13', answer: "TA'LIM"),
      ];
      final placed = CrosswordSolver.solve(topic1);
      final grid = <(int, int), String>{};
      for (final word in placed) {
        word.cells.forEach((pos, letter) {
          if (grid.containsKey(pos)) {
            expect(grid[pos], letter, reason: 'Conflict at $pos');
          }
          grid[pos] = letter;
        });
      }
      expect(placed.length, topic1.length);
    });
  });
}
