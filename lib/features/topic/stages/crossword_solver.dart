import 'dart:math';
import '../../../data/models/models.dart';

class PlacedWord {
  final int number;
  final CrosswordClue clue;
  final int row;
  final int col;
  final bool isHorizontal;

  const PlacedWord({
    required this.number,
    required this.clue,
    required this.row,
    required this.col,
    required this.isHorizontal,
  });

  String get answer =>
      clue.answer.toUpperCase().replaceAll("'", '').replaceAll('’', '');

  int get length => answer.length;

  Map<(int, int), String> get cells {
    final result = <(int, int), String>{};
    for (int i = 0; i < length; i++) {
      final r = isHorizontal ? row : row + i;
      final c = isHorizontal ? col + i : col;
      result[(r, c)] = answer[i];
    }
    return result;
  }
}

class CrosswordSolver {
  static List<PlacedWord> solve(List<CrosswordClue> clues) {
    if (clues.isEmpty) return [];

    final sorted = clues.toList()
      ..sort((a, b) {
        final al = _norm(a.answer).length;
        final bl = _norm(b.answer).length;
        return bl.compareTo(al);
      });

    final placed = <PlacedWord>[];
    final grid = <(int, int), String>{};

    // Pick longest horizontal word as anchor; fallback to longest overall.
    final anchor = sorted.firstWhere(
      (c) => _isH(c.orientation),
      orElse: () => sorted[0],
    );
    final remaining = sorted.where((c) => c != anchor).toList();

    _commit(
      PlacedWord(
        number: 0,
        clue: anchor,
        row: 0,
        col: 0,
        isHorizontal: _isH(anchor.orientation),
      ),
      placed,
      grid,
    );

    for (final clue in remaining) {
      final answer = _norm(clue.answer);
      final wantH = _isH(clue.orientation);

      PlacedWord? best;
      int bestScore = -1;

      for (final pw in placed) {
        final pwAns = pw.answer;
        for (int pi = 0; pi < pwAns.length; pi++) {
          for (int ai = 0; ai < answer.length; ai++) {
            if (pwAns[pi] != answer[ai]) continue;

            int row, col;
            if (pw.isHorizontal && !wantH) {
              row = pw.row - ai;
              col = pw.col + pi;
            } else if (!pw.isHorizontal && wantH) {
              row = pw.row + pi;
              col = pw.col - ai;
            } else {
              continue;
            }

            final candidate = PlacedWord(
              number: 0,
              clue: clue,
              row: row,
              col: col,
              isHorizontal: wantH,
            );

            if (!_valid(candidate, grid, placed)) continue;
            final score = _score(candidate, grid);
            if (score > bestScore) {
              bestScore = score;
              best = candidate;
            }
          }
        }
      }

      if (best != null) {
        _commit(best, placed, grid);
      } else {
        final maxRow = placed
            .map((w) => w.isHorizontal ? w.row : w.row + w.length - 1)
            .reduce(max);
        _commit(
          PlacedWord(
            number: 0,
            clue: clue,
            row: maxRow + 2,
            col: 0,
            isHorizontal: wantH,
          ),
          placed,
          grid,
        );
      }
    }

    return _number(placed);
  }

  static String _norm(String s) =>
      s.toUpperCase().replaceAll("'", '').replaceAll('’', '');

  static bool _isH(String orientation) {
    final l = orientation.toLowerCase();
    return l.contains('gor') || l == 'horizontal' || l.contains('across');
  }

  static void _commit(
    PlacedWord w,
    List<PlacedWord> placed,
    Map<(int, int), String> grid,
  ) {
    placed.add(w);
    grid.addAll(w.cells);
  }

  static bool _valid(
    PlacedWord c,
    Map<(int, int), String> grid,
    List<PlacedWord> placed,
  ) {
    final cells = c.cells;

    for (final e in cells.entries) {
      final pos = e.key;
      final letter = e.value;

      if (grid.containsKey(pos)) {
        if (grid[pos] != letter) return false;
        if (placed.any((w) =>
            w.isHorizontal == c.isHorizontal && w.cells.containsKey(pos))) {
          return false;
        }
      }
    }

    if (c.isHorizontal) {
      if (grid.containsKey((c.row, c.col - 1))) return false;
      if (grid.containsKey((c.row, c.col + c.length))) return false;
    } else {
      if (grid.containsKey((c.row - 1, c.col))) return false;
      if (grid.containsKey((c.row + c.length, c.col))) return false;
    }

    for (final pos in cells.keys) {
      if (grid.containsKey(pos)) continue;
      if (c.isHorizontal) {
        final above = (pos.$1 - 1, pos.$2);
        final below = (pos.$1 + 1, pos.$2);
        if (grid.containsKey(above) &&
            placed.any((w) => w.isHorizontal && w.cells.containsKey(above))) { return false; }
        if (grid.containsKey(below) &&
            placed.any((w) => w.isHorizontal && w.cells.containsKey(below))) { return false; }
      } else {
        final left = (pos.$1, pos.$2 - 1);
        final right = (pos.$1, pos.$2 + 1);
        if (grid.containsKey(left) &&
            placed.any((w) => !w.isHorizontal && w.cells.containsKey(left))) { return false; }
        if (grid.containsKey(right) &&
            placed.any((w) => !w.isHorizontal && w.cells.containsKey(right))) { return false; }
      }
    }

    if (!cells.keys.any((k) => grid.containsKey(k))) return false;

    return true;
  }

  static int _score(PlacedWord c, Map<(int, int), String> grid) =>
      c.cells.keys.where((k) => grid.containsKey(k)).length;

  static List<PlacedWord> _number(List<PlacedWord> raw) {
    final minRow = raw.map((w) => w.row).reduce(min);
    final minCol = raw.map((w) => w.col).reduce(min);

    final norm = raw
        .map((w) => PlacedWord(
              number: 0,
              clue: w.clue,
              row: w.row - minRow,
              col: w.col - minCol,
              isHorizontal: w.isHorizontal,
            ))
        .toList();

    // Sort by (row, col, isHorizontal) so each word gets a unique number
    // even when two words share the same start cell (H before V).
    final sorted = norm.toList()
      ..sort((a, b) {
        if (a.row != b.row) return a.row.compareTo(b.row);
        if (a.col != b.col) return a.col.compareTo(b.col);
        // H (true=1) before V (false=0): horizontal gets lower number
        return (b.isHorizontal ? 1 : 0).compareTo(a.isHorizontal ? 1 : 0);
      });

    final numMap = {
      for (int i = 0; i < sorted.length; i++)
        (sorted[i].row, sorted[i].col, sorted[i].isHorizontal): i + 1
    };

    return norm
        .map((w) => PlacedWord(
              number: numMap[(w.row, w.col, w.isHorizontal)]!,
              clue: w.clue,
              row: w.row,
              col: w.col,
              isHorizontal: w.isHorizontal,
            ))
        .toList();
  }
}
