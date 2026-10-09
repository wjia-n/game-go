import 'dart:math';

/// Pure Go rules engine — no Flutter, fully unit-testable.
/// Implements the authoritative RULES.md: area scoring conventions, ko +
/// positional superko, suicide rules, handicap placement.
///
/// Board encoding: 0 = empty, 1 = black, 2 = white. Index = row * size + col.
class GoEngine {
  static List<List<int>> starPoints(int size) => size == 9
      ? const [
          [2, 2],
          [2, 6],
          [6, 2],
          [6, 6],
          [4, 4]
        ]
      : size == 13
          ? const [
              [3, 3],
              [3, 9],
              [9, 3],
              [9, 9],
              [3, 6],
              [6, 3],
              [6, 9],
              [9, 6],
              [6, 6]
            ]
          : const [
              [3, 3],
              [3, 9],
              [3, 15],
              [9, 3],
              [9, 9],
              [9, 15],
              [15, 3],
              [15, 9],
              [15, 15]
            ];

  /// Traditional handicap placement order (row, col), 0-indexed.
  static List<List<int>> handicapPoints(int size, int count) {
    final order = size == 9
        ? const [
            [6, 2],
            [2, 6],
            [6, 6],
            [2, 2],
            [4, 4],
            [4, 2],
            [4, 6],
            [2, 4],
            [6, 4]
          ]
        : size == 13
            ? const [
                [9, 3],
                [3, 9],
                [9, 9],
                [3, 3],
                [6, 6],
                [6, 3],
                [6, 9],
                [3, 6],
                [9, 6]
              ]
            : const [
                [15, 3],
                [3, 15],
                [15, 15],
                [3, 3],
                [9, 9],
                [9, 3],
                [9, 15],
                [3, 9],
                [15, 9]
              ];
    return order.sublist(0, min(count, order.length));
  }

  static double defaultKomi(int size) => size == 9
      ? 4.5
      : size == 13
          ? 5.5
          : 6.5;

  static List<int> nbrs(int size, int i) {
    final r = i ~/ size, c = i % size, o = <int>[];
    if (r > 0) o.add(i - size);
    if (r < size - 1) o.add(i + size);
    if (c > 0) o.add(i - 1);
    if (c < size - 1) o.add(i + 1);
    return o;
  }

  static Set<int> group(List<int> b, int size, int s) {
    final col = b[s], seen = <int>{}, st = [s];
    while (st.isNotEmpty) {
      final i = st.removeLast();
      if (!seen.add(i)) continue;
      for (final n in nbrs(size, i)) {
        if (b[n] == col && !seen.contains(n)) st.add(n);
      }
    }
    return seen;
  }

  static int libs(List<int> b, int size, Set<int> g) {
    final l = <int>{};
    for (final i in g) {
      for (final n in nbrs(size, i)) {
        if (b[n] == 0) l.add(n);
      }
    }
    return l.length;
  }

  /// Plays on [b]; returns captures, or -1 for suicide.
  /// Capture takes precedence over suicide.
  static int playOn(List<int> b, int size, int i, int col) {
    b[i] = col;
    var cap = 0;
    final foe = 3 - col, done = <int>{};
    for (final n in nbrs(size, i)) {
      if (b[n] == foe && !done.contains(n)) {
        final g = group(b, size, n);
        done.addAll(g);
        if (libs(b, size, g) == 0) {
          for (final s in g) {
            b[s] = 0;
          }
          cap += g.length;
        }
      }
    }
    if (cap == 0 && libs(b, size, group(b, size, i)) == 0) {
      b[i] = 0;
      return -1;
    }
    return cap;
  }

  static String hash(List<int> b) => b.join();
}

/// Outcome of testing a candidate move without committing it.
class MoveCheck {
  final bool ok;
  final int captures;
  final String reason; // 'occupied' | 'suicide' | 'ko' | 'ok'
  const MoveCheck(this.ok, this.captures, this.reason);
}

/// Full legality test: occupied, suicide, and positional superko.
MoveCheck checkMove(
    List<int> board, int size, int i, int col, Set<String> seenHashes) {
  if (board[i] != 0) return const MoveCheck(false, 0, 'occupied');
  final b = List<int>.from(board);
  final cap = GoEngine.playOn(b, size, i, col);
  if (cap < 0) return const MoveCheck(false, 0, 'suicide');
  if (seenHashes.contains(GoEngine.hash(b))) {
    return const MoveCheck(false, 0, 'ko');
  }
  return MoveCheck(true, cap, 'ok');
}

/// Area scoring (Chinese style): stones on board + surrounded territory.
class AreaScore {
  final double black, white;
  final Map<int, int> territory; // point -> color
  const AreaScore(this.black, this.white, this.territory);
}

AreaScore areaScore(List<int> board, int size, Set<int> dead, double komi) {
  final b = List<int>.from(board);
  for (final i in dead) {
    if (i >= 0 && i < b.length) b[i] = 0;
  }
  final territory = <int, int>{};
  final seen = <int>{};
  var sB = 0.0, sW = komi;
  for (final v in b) {
    if (v == 1) sB++;
    if (v == 2) sW++;
  }
  for (var i = 0; i < b.length; i++) {
    if (b[i] != 0 || seen.contains(i)) continue;
    final region = <int>[], stack = [i], border = <int>{};
    while (stack.isNotEmpty) {
      final j = stack.removeLast();
      if (!seen.add(j)) continue;
      region.add(j);
      for (final n in GoEngine.nbrs(size, j)) {
        if (b[n] == 0) {
          if (!seen.contains(n)) stack.add(n);
        } else {
          border.add(b[n]);
        }
      }
    }
    if (border.length == 1) {
      final o = border.first;
      for (final j in region) {
        territory[j] = o;
      }
      if (o == 1) {
        sB += region.length;
      } else {
        sW += region.length;
      }
    }
  }
  return AreaScore(sB, sW, territory);
}

/// Heuristic dead-group detection for the scoring review.
/// A group is guessed dead if it has fewer than 2 eyes and every one of its
/// liberties touches an enemy stone. The player can toggle any group.
Set<int> guessDead(List<int> board, int size) {
  final dead = <int>{};
  final seen = <int>{};
  for (var i = 0; i < board.length; i++) {
    if (board[i] == 0 || seen.contains(i)) continue;
    final g = GoEngine.group(board, size, i);
    seen.addAll(g);
    final col = board[i];
    final foe = 3 - col;
    // count eyes: empty regions bordered solely by this color
    var eyes = 0;
    final libSet = <int>{};
    for (final s in g) {
      for (final n in GoEngine.nbrs(size, s)) {
        if (board[n] == 0) libSet.add(n);
      }
    }
    final eyeSeen = <int>{};
    for (final l in libSet) {
      if (eyeSeen.contains(l)) continue;
      final region = <int>[], stack = [l], border = <int>{};
      while (stack.isNotEmpty) {
        final j = stack.removeLast();
        if (!eyeSeen.add(j)) continue;
        region.add(j);
        for (final n in GoEngine.nbrs(size, j)) {
          if (board[n] == 0) {
            if (!eyeSeen.contains(n)) stack.add(n);
          } else {
            border.add(board[n]);
          }
        }
      }
      if (border.length == 1 && border.first == col && region.length <= size) {
        eyes++;
      }
    }
    if (eyes >= 2) continue;
    var allFoe = libSet.isNotEmpty;
    for (final l in libSet) {
      final touchesFoe = GoEngine.nbrs(size, l).any((n) => board[n] == foe);
      if (!touchesFoe) {
        allFoe = false;
        break;
      }
    }
    if (allFoe) dead.addAll(g);
  }
  return dead;
}
