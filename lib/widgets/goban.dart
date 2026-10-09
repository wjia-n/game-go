import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/go_engine.dart';
import '../theme.dart';

/// Kaya-wood goban with physical slate & clamshell stones.
/// Single soft light source, upper-left (135°), like shoji daylight.
class GobanBoard extends StatefulWidget {
  final List<int> board;
  final int size;
  final int lastMove;
  final int invalidAt;
  final Set<int> dead;
  final Map<int, int> territory;
  final bool showCoordinates;
  final ValueChanged<int> onTap;

  const GobanBoard({
    super.key,
    required this.board,
    required this.size,
    required this.lastMove,
    required this.invalidAt,
    required this.dead,
    required this.territory,
    required this.showCoordinates,
    required this.onTap,
  });

  @override
  State<GobanBoard> createState() => _GobanBoardState();
}

class _GobanBoardState extends State<GobanBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _place;
  late final Animation<double> _scale;
  int _animatedFor = -2;

  @override
  void initState() {
    super.initState();
    _place = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.28, end: 0.96)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 55),
    ]).animate(_place);
    _place.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant GobanBoard old) {
    super.didUpdateWidget(old);
    if (widget.lastMove != old.lastMove &&
        widget.lastMove >= 0 &&
        widget.lastMove != _animatedFor) {
      _animatedFor = widget.lastMove;
      _place.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final side = min(cons.maxWidth, cons.maxHeight);
        return GestureDetector(
          onTapUp: (d) {
            final rb = ctx.findRenderObject() as RenderBox?;
            if (rb == null) return;
            final i = _hitTest(rb, d.globalPosition, side);
            if (i != null) widget.onTap(i);
          },
          child: SizedBox(
            width: side,
            height: side,
            child: CustomPaint(
              painter: _GobanPainter(
                board: widget.board,
                size: widget.size,
                lastMove: widget.lastMove,
                invalidAt: widget.invalidAt,
                dead: widget.dead,
                territory: widget.territory,
                showCoordinates: widget.showCoordinates,
                placeScale: _place.isAnimating || _place.value > 0
                    ? _scale.value
                    : 1.0,
                placing: widget.lastMove,
              ),
            ),
          ),
        );
      },
    );
  }

  int? _hitTest(RenderBox rb, Offset global, double side) {
    final lp = rb.globalToLocal(global);
    final m = _GobanPainter.metrics(side, widget.size, widget.showCoordinates);
    // nearest intersection:
    final cc = ((lp.dx - m.pad) / m.cell).round();
    final rr = ((lp.dy - m.pad) / m.cell).round();
    if (rr < 0 || rr >= widget.size || cc < 0 || cc >= widget.size) {
      return null;
    }
    // require the tap to be reasonably close to the intersection
    final dx = (lp.dx - (m.pad + cc * m.cell)).abs();
    final dy = (lp.dy - (m.pad + rr * m.cell)).abs();
    if (dx > m.cell * 0.48 || dy > m.cell * 0.48) return null;
    return rr * widget.size + cc;
  }
}

class _Metrics {
  final double pad, cell, edge;
  _Metrics(this.pad, this.cell, this.edge);
}

class _GobanPainter extends CustomPainter {
  final List<int> board;
  final int size, lastMove, invalidAt, placing;
  final Set<int> dead;
  final Map<int, int> territory;
  final bool showCoordinates;
  final double placeScale;

  _GobanPainter({
    required this.board,
    required this.size,
    required this.lastMove,
    required this.invalidAt,
    required this.dead,
    required this.territory,
    required this.showCoordinates,
    required this.placeScale,
    required this.placing,
  });

  static _Metrics metrics(double side, int size, bool coords) {
    final coordRoom = coords ? side * 0.055 : 0.0;
    final pad = side * 0.075 + coordRoom;
    final cell = (side - pad * 2) / (size - 1);
    return _Metrics(pad, cell, pad + (size - 1) * cell);
  }

  static const _cols = 'ABCDEFGHJKLMNOPQRST';

  @override
  void paint(Canvas canvas, Size s) {
    final side = s.width;
    final m = metrics(side, size, showCoordinates);
    Offset pt(int i) =>
        Offset(m.pad + (i % size) * m.cell, m.pad + (i ~/ size) * m.cell);

    _paintWood(canvas, s);
    _paintGrid(canvas, m, pt);
    _paintCoordinates(canvas, m);
    _paintTerritory(canvas, pt);
    _paintStones(canvas, m, pt);
    if (invalidAt >= 0) _paintInvalid(canvas, pt(invalidAt), m);
  }

  void _paintWood(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    final wood = BoardLook.wood;
    // board wood base, faint vertical sheen (light from upper-left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [wood.light, wood.mid, wood.deep],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // straight wood grain — deterministic so it never shimmers
    final rnd = Random(20261009);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var k = 0; k < 26; k++) {
      final x = rnd.nextDouble() * s.width;
      final wob = 2 + rnd.nextDouble() * 5;
      final path = Path()..moveTo(x, 0);
      for (var y = 0.0; y <= s.height; y += 24) {
        path.lineTo(x + sin(y / 90 + k) * wob, y);
      }
      grain.color = wood.grain.withValues(
          alpha: (wood.grain.a * (0.5 + rnd.nextDouble() * 0.8)).clamp(0.02, 0.25));
      canvas.drawPath(path, grain);
    }
    // rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = wood.rim,
    );
    // soft ambient occlusion inside the rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(11)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.black.withValues(alpha: 0.10),
    );
  }

  void _paintGrid(Canvas canvas, _Metrics m, Offset Function(int) pt) {
    final wood = BoardLook.wood;
    final grid = Paint()
      ..color = wood.grid
      ..strokeWidth = (m.cell * 0.035).clamp(1.0, 2.2);
    for (var k = 0; k < size; k++) {
      final p = m.pad + k * m.cell;
      canvas.drawLine(Offset(m.pad, p), Offset(m.edge, p), grid);
      canvas.drawLine(Offset(p, m.pad), Offset(p, m.edge), grid);
    }
    final star = Paint()..color = wood.grid;
    for (final sp in GoEngine.starPoints(size)) {
      canvas.drawCircle(
          pt(sp[0] * size + sp[1]), (m.cell * 0.085).clamp(1.8, 4.5), star);
    }
  }

  void _paintCoordinates(Canvas canvas, _Metrics m) {
    if (!showCoordinates) return;
    final style = GoTheme.label((m.cell * 0.32).clamp(8.0, 12.0));
    for (var k = 0; k < size; k++) {
      final letter = _cols[k];
      final num = '${size - k}';
      _text(canvas, letter, Offset(m.pad + k * m.cell, m.pad - m.cell * 0.62), style);
      _text(canvas, num, Offset(m.pad - m.cell * 0.62, m.pad + k * m.cell), style);
    }
  }

  void _text(Canvas canvas, String t, Offset at, TextStyle style) {
    final tp = TextPainter(
        text: TextSpan(text: t, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintTerritory(Canvas canvas, Offset Function(int) pt) {
    if (territory.isEmpty) return;
    for (final e in territory.entries) {
      final p = pt(e.key);
      final r = 5.0;
      canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = (e.value == 1 ? GoTheme.slateDeep : GoTheme.clamshell)
                .withValues(alpha: 0.55));
    }
  }

  void _paintStones(Canvas canvas, _Metrics m, Offset Function(int) pt) {
    final r = m.cell * 0.47;
    for (var i = 0; i < board.length; i++) {
      final v = board[i];
      if (v == 0) continue;
      var rr = r;
      if (i == placing && i == lastMove) rr *= placeScale;
      final p = pt(i);
      final isDead = dead.contains(i);

      // contact shadow — firm, offset down-right (light from upper-left)
      canvas.drawOval(
        Rect.fromCenter(
            center: p + Offset(rr * 0.14, rr * 0.20),
            width: rr * 1.9,
            height: rr * 1.75),
        Paint()..color = GoTheme.stoneShadow.withValues(alpha: isDead ? 0.15 : 1),
      );

      final rect = Rect.fromCircle(center: p, radius: rr);
      final stone = BoardLook.stone;
      if (v == 1) {
        // black stone: physical material per the active stone style
        canvas.drawCircle(
            p,
            rr,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 1.1,
                colors: [stone.blackTop, stone.blackDeep],
              ).createShader(rect)
              ..color = Colors.white.withValues(alpha: isDead ? 0.35 : 1.0));
        // specular glint
        canvas.drawOval(
            Rect.fromCenter(
                center: p + Offset(-rr * 0.32, -rr * 0.36),
                width: rr * 0.55,
                height: rr * 0.38),
            Paint()
              ..color = (isDead
                      ? stone.blackGlint.withValues(alpha: 0.06)
                      : stone.blackGlint));
      } else {
        // white stone: physical material per the active stone style
        canvas.drawCircle(
            p,
            rr,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-0.3, -0.35),
                radius: 1.15,
                colors: [stone.whiteTop, stone.whiteMid, stone.whiteDeep],
              ).createShader(rect)
              ..color = Colors.white.withValues(alpha: isDead ? 0.35 : 1.0));
        // marbled bands
        final band = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rr * 0.06
          ..color = isDead
              ? stone.whiteBand.withValues(alpha: 0.05)
              : stone.whiteBand;
        canvas.drawArc(rect.deflate(rr * 0.35), 0.4, 1.8, false, band);
        canvas.drawArc(rect.deflate(rr * 0.6), 3.4, 1.4, false, band);
        // warm rim
        canvas.drawCircle(
            p,
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = rr * 0.10
              ..color = isDead
                  ? stone.whiteRim.withValues(alpha: 0.08)
                  : stone.whiteRim);
      }

      if (isDead) {
        // hollowed: ring + cross until confirmed
        canvas.drawCircle(
            p,
            rr * 0.55,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = GoTheme.error.withValues(alpha: 0.7));
      } else if (i == lastMove) {
        // traditional contrasting dot on the last move
        canvas.drawCircle(
            p,
            rr * 0.22,
            Paint()
              ..color = v == 1
                  ? GoTheme.clamshell.withValues(alpha: 0.9)
                  : GoTheme.sumi.withValues(alpha: 0.85));
      }
    }
  }

  void _paintInvalid(Canvas canvas, Offset p, _Metrics m) {
    final r = m.cell * 0.47;
    canvas.drawCircle(
        p,
        r * 1.05,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = GoTheme.error.withValues(alpha: 0.85));
    canvas.drawCircle(
        p, r * 0.9, Paint()..color = GoTheme.error.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(covariant _GobanPainter o) =>
      o.board != board ||
      o.size != size ||
      o.lastMove != lastMove ||
      o.invalidAt != invalidAt ||
      o.dead != dead ||
      o.territory != territory ||
      o.showCoordinates != showCoordinates ||
      o.placeScale != placeScale;
}
