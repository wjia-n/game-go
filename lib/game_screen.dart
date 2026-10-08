import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Go — the ancient game of territory. Black vs White on 9x9, 13x13 or 19x19.
class GoScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const GoScreen({super.key, required this.players, required this.callbacks});
  @override
  State<GoScreen> createState() => _GoScreenState();
}

enum _Phase { play, markDead, done }

/// Pure Go rules engine — no Flutter, fully unit-testable.
class GoEngine {
  static List<List<int>> starPoints(int size) => size == 9
      ? const [[2, 2], [2, 6], [6, 2], [6, 6], [4, 4]]
      : size == 13
          ? const [[3, 3], [3, 9], [9, 3], [9, 9], [3, 6], [6, 3], [6, 9], [9, 6], [6, 6]]
          : const [[3, 3], [3, 9], [3, 15], [9, 3], [9, 9], [9, 15], [15, 3], [15, 9], [15, 15]];

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

class _GoScreenState extends State<GoScreen> {
  final _rnd = Random();
  int size = 9;
  List<int> board = [];
  int turn = 1; // 1 = black = players[0], 2 = white = players[1]
  int moves = 0, capByBlack = 0, capByWhite = 0, passes = 0, lastMove = -1, _gen = 0;
  List<String> hashes = [];
  final List<VoidCallback> _undos = [];
  _Phase phase = _Phase.play;
  Set<int> dead = {};
  Map<int, int> terr = {};
  bool over = false;
  String scoreLine = '';

  @override
  void initState() {
    super.initState();
    _newGame(9);
  }

  void _newGame(int s) {
    _gen++;
    setState(() {
      size = s;
      board = List.filled(s * s, 0);
      turn = 1;
      moves = 0;
      capByBlack = 0;
      capByWhite = 0;
      passes = 0;
      lastMove = -1;
      over = false;
      hashes = [_hash(board)];
      _undos.clear();
      dead = {};
      terr = {};
      phase = _Phase.play;
      scoreLine = '';
    });
    widget.callbacks.setActivePlayer(0);
    _maybeBot();
  }

  int get _me => turn == 1 ? 0 : 1;

  // ---------------- engine (pure logic lives in GoEngine) ----------------

  List<int> _nbrs(int i) => GoEngine.nbrs(size, i);
  Set<int> _group(List<int> b, int s) => GoEngine.group(b, size, s);
  int _libs(List<int> b, Set<int> g) => GoEngine.libs(b, size, g);

  /// Plays on [b]; returns captures, or -1 for suicide.
  int _playOn(List<int> b, int i, int col) => GoEngine.playOn(b, size, i, col);

  String _hash(List<int> b) => GoEngine.hash(b);

  bool _legal(int i, int col) {
    if (board[i] != 0) return false;
    final b = List<int>.from(board);
    if (_playOn(b, i, col) < 0) return false;
    return hashes.length < 2 || _hash(b) != hashes[hashes.length - 2]; // ko
  }

  // ---------------- moves ----------------

  void _pushUndo() {
    final b = List<int>.from(board), h = List<String>.from(hashes), d = Set<int>.from(dead);
    final t = turn, m = moves, cb = capByBlack, cw = capByWhite, p = passes, lm = lastMove, ph = phase;
    _undos.add(() {
      board = b;
      hashes = h;
      dead = d;
      turn = t;
      moves = m;
      capByBlack = cb;
      capByWhite = cw;
      passes = p;
      lastMove = lm;
      phase = ph;
    });
    if (_undos.length > 80) _undos.removeAt(0);
  }

  void _undo() {
    if (_undos.isEmpty || over) return;
    _gen++;
    _undos.removeLast()();
    if (_undos.isNotEmpty && widget.players[_me].isBot) _undos.removeLast()();
    setState(() {});
    widget.callbacks.setActivePlayer(_me);
    Sfx.click();
  }

  void _doMove(int i) {
    if (!_legal(i, turn)) return;
    _gen++;
    _pushUndo();
    final b = List<int>.from(board);
    final cap = _playOn(b, i, turn);
    board = b;
    if (turn == 1) {
      capByBlack += cap;
    } else {
      capByWhite += cap;
    }
    hashes.add(_hash(board));
    moves++;
    passes = 0;
    lastMove = i;
    Sfx.move();
    _advance();
  }

  void _pass() {
    if (over || phase != _Phase.play) return;
    _gen++;
    _pushUndo();
    passes++;
    lastMove = -1;
    Sfx.tap();
    if (passes >= 2) {
      setState(() => phase = _Phase.markDead);
      return;
    }
    _advance();
  }

  void _advance() {
    turn = 3 - turn;
    setState(() {});
    widget.callbacks.setActivePlayer(_me);
    _maybeBot();
  }

  void _onTapPoint(int i) {
    if (over) return;
    if (phase == _Phase.markDead) {
      if (board[i] == 0) return;
      setState(() {
        final g = _group(board, i);
        final nd = Set<int>.from(dead);
        if (nd.contains(i)) {
          nd.removeAll(g);
        } else {
          nd.addAll(g);
        }
        dead = nd;
      });
      Sfx.tap();
      return;
    }
    if (phase != _Phase.play || widget.players[_me].isBot) return;
    _doMove(i);
  }

  // ---------------- bot ----------------

  void _maybeBot() {
    if (over || phase != _Phase.play || !widget.players[_me].isBot) return;
    final g = _gen;
    Future.delayed(Duration(milliseconds: 650 + _rnd.nextInt(350)), () {
      if (!mounted || g != _gen || over || phase != _Phase.play) return;
      if (!widget.players[_me].isBot) return;
      _botPlay();
    });
  }

  double _eval(int i) {
    final b = List<int>.from(board);
    final cap = _playOn(b, i, turn);
    var s = cap * 12.0;
    for (final n in _nbrs(i)) {
      if (board[n] == turn) {
        final g = _group(board, n);
        if (_libs(board, g) == 1) s += g.length * 8.0; // rescue from atari
      } else if (board[n] == 3 - turn) {
        s += 0.3; // likes contact fights
      }
    }
    final r = i ~/ size, c = i % size;
    if (cap == 0 && (r == 0 || c == 0 || r == size - 1 || c == size - 1)) s -= 2.0;
    if (moves < size * 2) {
      if (GoEngine.starPoints(size).any((p) => p[0] == r && p[1] == c)) s += 3.0;
      if ((r == 2 || r == size - 3) && (c == 2 || c == size - 3)) s += 2.0; // 3-3
    }
    return s + _rnd.nextDouble() * 3.0; // jitter
  }

  void _botPlay() {
    var best = -1e9, pick = -1;
    for (var i = 0; i < board.length; i++) {
      if (!_legal(i, turn)) continue;
      final s = _eval(i);
      if (s > best) {
        best = s;
        pick = i;
      }
    }
    if (pick < 0 || (best < 2.0 && moves > size * size * 0.55)) {
      _pass(); // nothing tasty left — bow out gracefully
      return;
    }
    _doMove(pick);
  }

  // ---------------- scoring (Chinese area) ----------------

  void _countScore() {
    final b = List<int>.from(board);
    for (final i in dead) {
      if (b[i] == 1) capByWhite++;
      if (b[i] == 2) capByBlack++;
      b[i] = 0;
    }
    terr = {};
    final seen = <int>{};
    var sB = 0.0, sW = 7.5; // komi
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
        for (final n in _nbrs(j)) {
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
          terr[j] = o;
        }
        if (o == 1) {
          sB += region.length;
        } else {
          sW += region.length;
        }
      }
    }
    over = true;
    phase = _Phase.done;
    widget.players[0].score = sB.round();
    widget.players[1].score = sW.round();
    widget.callbacks.refreshHud();
    final blackWins = sB > sW;
    scoreLine = '⚫ ${sB.toStringAsFixed(1)}  ·  ⚪ ${sW.toStringAsFixed(1)}   (komi 7.5)';
    setState(() {});
    widget.callbacks.finish(
      winner: widget.players[blackWins ? 0 : 1],
      headline: '${blackWins ? '⚫ Black' : '⚪ White'} wins by ${(sB - sW).abs().toStringAsFixed(1)}!',
      subline: scoreLine,
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final me = widget.players[_me];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ScoreChips(players: widget.players, activeIndex: _me),
          const SizedBox(height: 8),
          if (phase == _Phase.markDead)
            Text('☝️ Tap stone groups to toggle them dead, then count it up',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 14))
          else if (over)
            Text(scoreLine,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 15))
          else
            TurnBanner(
                player: me,
                action: me.isBot
                    ? ' is thinking… 🤖'
                    : (turn == 1 ? ', your move ⚫' : ', your move ⚪')),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: t.radius,
                    boxShadow: [
                      BoxShadow(
                          color: t.primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Builder(
                    builder: (ctx) => GestureDetector(
                      onTapUp: (d) {
                        final rb = ctx.findRenderObject() as RenderBox?;
                        if (rb == null) return;
                        final w = rb.size.width;
                        final pad = w * 0.07;
                        final cell = (w - pad * 2) / (size - 1);
                        final lp = rb.globalToLocal(d.globalPosition);
                        final c = ((lp.dx - pad) / cell).round();
                        final r = ((lp.dy - pad) / cell).round();
                        if (r < 0 || r >= size || c < 0 || c >= size) return;
                        _onTapPoint(r * size + c);
                      },
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(lastMove),
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.elasticOut,
                        builder: (_, s, _) => CustomPaint(
                          painter: _GoPainter(
                            board: board,
                            size: size,
                            t: t,
                            lastMove: lastMove,
                            placeScale: s,
                            dead: dead,
                            terr: terr,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'Move $moves · ⚫ captured $capByBlack · ⚪ captured $capByWhite${passes == 1 ? ' · 1 pass' : ''}',
              style: TextStyle(color: t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buttons(),
        ],
      ),
    );
  }

  Widget _buttons() {
    if (phase == _Phase.done) return const SizedBox.shrink();
    if (phase == _Phase.markDead) {
      return WajihaButton(label: 'Count the score', emoji: '🧮', onTap: _countScore);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WajihaButton(label: 'Pass', emoji: '⏭️', fontSize: 15, primary: false, onTap: _pass),
            const SizedBox(width: 10),
            WajihaButton(label: 'Undo', emoji: '↩️', fontSize: 15, primary: false, onTap: _undo),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final s in [9, 13, 19])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: WajihaButton(
                    label: '${s}x$s', fontSize: 13, primary: size == s, onTap: () => _newGame(s)),
              ),
          ],
        ),
      ],
    );
  }
}

class _GoPainter extends CustomPainter {
  final List<int> board;
  final int size;
  final GameTheme t;
  final int lastMove;
  final double placeScale;
  final Set<int> dead;
  final Map<int, int> terr;

  const _GoPainter({
    required this.board,
    required this.size,
    required this.t,
    required this.lastMove,
    required this.placeScale,
    required this.dead,
    required this.terr,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final pad = s.width * 0.07;
    final cell = (s.width - pad * 2) / (size - 1);
    Offset pt(int i) => Offset(pad + (i % size) * cell, pad + (i ~/ size) * cell);

    // wooden-feel board from theme colors
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16)),
      Paint()
        ..shader = LinearGradient(
          colors: [t.surface, t.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & s),
    );

    // grid
    final edge = pad + (size - 1) * cell;
    final grid = Paint()
      ..color = t.muted.withValues(alpha: 0.7)
      ..strokeWidth = (cell * 0.035).clamp(1.0, 2.0);
    for (var k = 0; k < size; k++) {
      final p = pad + k * cell;
      canvas.drawLine(Offset(pad, p), Offset(edge, p), grid);
      canvas.drawLine(Offset(p, pad), Offset(p, edge), grid);
    }

    // star points
    final star = Paint()..color = t.muted;
    for (final sp in GoEngine.starPoints(size)) {
      canvas.drawCircle(pt(sp[0] * size + sp[1]), (cell * 0.09).clamp(2.0, 5.0), star);
    }

    // territory markers on the final board
    if (terr.isNotEmpty) {
      for (final e in terr.entries) {
        final p = pt(e.key);
        final r = cell * 0.14;
        canvas.drawRect(
          Rect.fromCenter(center: p, width: r * 2, height: r * 2),
          Paint()
            ..color = (e.value == 1 ? const Color(0xFF1c1c22) : const Color(0xFFf2f2f7))
                .withValues(alpha: 0.6),
        );
      }
    }

    // stones
    for (var i = 0; i < board.length; i++) {
      final v = board[i];
      if (v == 0) continue;
      var r = cell * 0.46;
      if (i == lastMove) r *= placeScale;
      final p = pt(i);
      canvas.drawCircle(p + Offset(r * 0.1, r * 0.16), r,
          Paint()..color = Colors.black.withValues(alpha: 0.25));
      final grad = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: v == 1
            ? const [Color(0xFF55555e), Color(0xFF0e0e12)]
            : const [Color(0xFFFFFFFF), Color(0xFFc6c6d2)],
      );
      final isDead = dead.contains(i);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..shader = grad.createShader(Rect.fromCircle(center: p, radius: r))
          ..color = Colors.white.withValues(alpha: isDead ? 0.35 : 1.0),
      );
      if (isDead) {
        final x = Paint()
          ..color = t.accent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        final d = r * 0.4;
        canvas.drawLine(p + Offset(-d, -d), p + Offset(d, d), x);
        canvas.drawLine(p + Offset(-d, d), p + Offset(d, -d), x);
      } else if (i == lastMove) {
        canvas.drawCircle(
            p,
            r * 0.32,
            Paint()
              ..color = t.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GoPainter o) =>
      o.board != board ||
      o.lastMove != lastMove ||
      o.placeScale != placeScale ||
      o.dead != dead ||
      o.terr != terr ||
      o.size != size;
}
