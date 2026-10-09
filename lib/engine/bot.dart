import 'dart:math';

import 'go_engine.dart';

enum BotDifficulty { easy, medium, hard }

/// Bot move selection per RULES.md §11.
/// The generator always filters illegal moves (occupied / suicide / ko / superko).
class GoBot {
  /// Returns a board index, or -1 to pass.
  static int chooseMove({
    required List<int> board,
    required int size,
    required int color,
    required Set<String> seenHashes,
    required int moves,
    required int lastMove,
    required Random rng,
    required BotDifficulty difficulty,
  }) {
    final legal = _legalMoves(board, size, color, seenHashes);
    if (legal.isEmpty) return -1;
    switch (difficulty) {
      case BotDifficulty.easy:
        return _easy(board, size, color, moves, legal, rng);
      case BotDifficulty.medium:
        return _medium(board, size, color, moves, legal, rng);
      case BotDifficulty.hard:
        return _hard(board, size, color, moves, lastMove, legal, seenHashes, rng);
    }
  }

  static List<_Cand> _legalMoves(
      List<int> board, int size, int color, Set<String> seenHashes) {
    final out = <_Cand>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i] != 0) continue;
      final c = checkMove(board, size, i, color, seenHashes);
      if (c.ok) out.add(_Cand(i, c.captures));
    }
    return out;
  }

  static bool _isStar(int size, int i) {
    final r = i ~/ size, c = i % size;
    return GoEngine.starPoints(size).any((p) => p[0] == r && p[1] == c);
  }

  // --- Easy: random-ish, biased to captures, atari rescues, near stones, stars.
  static int _easy(List<int> board, int size, int color, int moves,
      List<_Cand> legal, Random rng) {
    var best = -1e9, pick = legal[0].i;
    for (final c in legal) {
      var s = _baseScore(board, size, color, moves, c) + rng.nextDouble() * 14;
      if (s > best) {
        best = s;
        pick = c.i;
      }
    }
    // Drift into a graceful endgame.
    if (best < 1.5 && moves > size * size * 0.5) return -1;
    return pick;
  }

  // --- Medium: easy + liberty discipline, opening shape, no own-territory fill.
  static int _medium(List<int> board, int size, int color, int moves,
      List<_Cand> legal, Random rng) {
    var best = -1e9, pick = legal[0].i;
    for (final c in legal) {
      final b = List<int>.from(board);
      GoEngine.playOn(b, size, c.i, color);
      var s = _baseScore(board, size, color, moves, c);
      // avoid self-atari: don't leave own new group with 1 liberty
      final g = GoEngine.group(b, size, c.i);
      final l = GoEngine.libs(b, size, g);
      if (l == 1) {
        s -= 14; // unless it captures
        if (c.captures > 0) s += 14;
      } else {
        s += l * 0.6; // prefer roomy groups
      }
      // corner-first opening shape
      final r = c.i ~/ size, cc = c.i % size;
      final edge = r == 0 || cc == 0 || r == size - 1 || cc == size - 1;
      if (moves < size * 2 && !edge) s += 1.5;
      if (moves >= size * 2 && edge) s -= 1.0;
      // don't fill own certain territory late
      if (moves > size * size * 0.45 && _insideOwnTerritory(b, size, c.i, color)) {
        s -= 8;
      }
      s += rng.nextDouble() * 4;
      if (s > best) {
        best = s;
        pick = c.i;
      }
    }
    if (best < 1.0 && moves > size * size * 0.5) return -1;
    return pick;
  }

  // --- Hard: medium + shallow 2-ply search, seeded RNG (deterministic).
  static int _hard(
      List<int> board,
      int size,
      int color,
      int moves,
      int lastMove,
      List<_Cand> legal,
      Set<String> seenHashes,
      Random rng) {
    final foe = 3 - color;
    final scored = legal
        .map((c) => _Scored(
            c.i, _cheapEval(board, size, color, moves, c) + rng.nextDouble()))
        .toList()
      ..sort((a, b) => b.v.compareTo(a.v));
    final candCount = min(12, scored.length);
    var best = -1e100;
    final shortlist = <int>[];
    final oppCount = min(8, legal.length);
    for (var k = 0; k < candCount; k++) {
      final i = scored[k].i;
      final b = List<int>.from(board);
      final cap = GoEngine.playOn(b, size, i, color);
      final h = Set<String>.from(seenHashes)..add(GoEngine.hash(b));
      // opponent's best reply
      var worst = 1e100;
      final replies = _legalMoves(b, size, foe, h)
          .map((c) => _Scored(c.i, _cheapEval(b, size, foe, moves, c)))
          .toList()
        ..sort((a, b2) => b2.v.compareTo(a.v));
      for (var j = 0; j < min(oppCount, replies.length); j++) {
        final b2 = List<int>.from(b);
        GoEngine.playOn(b2, size, replies[j].i, foe);
        final v = _staticEval(b2, size, color, cap);
        if (v < worst) worst = v;
      }
      if (replies.isEmpty) worst = _staticEval(b, size, color, cap);
      // ko-threat awareness: don't walk into an immediate ko recapture
      if (checkMove(board, size, i, foe, seenHashes).reason == 'ko') {
        worst -= 6;
      }
      if (worst > best + 0.5) {
        best = worst;
        shortlist
          ..clear()
          ..add(i);
      } else if ((worst - best).abs() <= 0.5) {
        shortlist.add(i);
      }
    }
    // deterministic tie-break: prefer moves near the last played stone
    var pick = shortlist.first;
    if (lastMove >= 0 && shortlist.length > 1) {
      pick = shortlist.reduce((a, b) =>
          _dist(size, a, lastMove) <= _dist(size, b, lastMove) ? a : b);
    }
    // endgame: fill dame in a calm order instead of passing too early
    if (best < -2 && moves > size * size * 0.55) return -1;
    return pick;
  }

  static int _dist(int size, int a, int b) {
    final dr = (a ~/ size - b ~/ size).abs();
    final dc = (a % size - b % size).abs();
    return dr + dc;
  }

  static double _baseScore(
      List<int> board, int size, int color, int moves, _Cand c) {
    var s = c.captures * 14.0;
    for (final n in GoEngine.nbrs(size, c.i)) {
      if (board[n] == color) {
        final g = GoEngine.group(board, size, n);
        if (GoEngine.libs(board, size, g) == 1) {
          s += g.length * 9.0; // rescue from atari
        } else {
          s += 0.4; // stay near friends
        }
      } else if (board[n] == 3 - color) {
        s += 0.5; // likes contact
      }
    }
    if (moves < size * 2) {
      if (_isStar(size, c.i)) s += 3.5;
      final r = c.i ~/ size, cc = c.i % size;
      if ((r == 2 || r == size - 3) && (cc == 2 || cc == size - 3)) s += 2.0;
    }
    return s;
  }

  static double _cheapEval(
      List<int> board, int size, int color, int moves, _Cand c) {
    final b = List<int>.from(board);
    GoEngine.playOn(b, size, c.i, color);
    final g = GoEngine.group(b, size, c.i);
    var s = _baseScore(board, size, color, moves, c);
    final l = GoEngine.libs(b, size, g);
    if (l == 1 && c.captures == 0) {
      s -= 14;
    } else {
      s += l * 0.8;
    }
    s += _staticEval(b, size, color, 0) * 0.15;
    return s;
  }

  /// Liberty-based static evaluation: stones + territory estimate + influence.
  static double _staticEval(List<int> b, int size, int color, int capturedNow) {
    final foe = 3 - color;
    var my = 0, fo = 0;
    for (final v in b) {
      if (v == color) {
        my++;
      } else if (v == foe) {
        fo++;
      }
    }
    // quick territory/influence estimate: empty regions bordered by one color
    var terr = 0.0;
    final seen = <int>{};
    for (var i = 0; i < b.length; i++) {
      if (b[i] != 0 || seen.contains(i)) continue;
      final stack = [i], border = <int>{};
      var n = 0;
      while (stack.isNotEmpty) {
        final j = stack.removeLast();
        if (!seen.add(j)) continue;
        n++;
        for (final m in GoEngine.nbrs(size, j)) {
          if (b[m] == 0) {
            if (!seen.contains(m)) stack.add(m);
          } else {
            border.add(b[m]);
          }
        }
      }
      if (border.length == 1) {
        terr += (border.first == color ? n : -n) * 0.7;
      }
    }
    return (my - fo).toDouble() + terr + capturedNow * 1.5;
  }

  static bool _insideOwnTerritory(List<int> b, int size, int i, int color) {
    // every orthogonal neighbor is my stone or off... i is my new stone;
    // check the empty region it would fill was single-color bordered.
    for (final n in GoEngine.nbrs(size, i)) {
      if (b[n] != color && b[n] != 0) return false;
    }
    return true;
  }
}

class _Cand {
  final int i, captures;
  const _Cand(this.i, this.captures);
}

class _Scored {
  final int i;
  final double v;
  const _Scored(this.i, this.v);
}
