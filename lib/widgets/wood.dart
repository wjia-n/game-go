import 'package:flutter/material.dart';

import '../theme.dart';

/// Physical wooden UI components — pressed = inset shadow + 0.98 scale
/// (weight, not glow). No neon, no gradients-as-decoration.

class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final double fontSize;
  final double? width;
  const WoodButton(
      {super.key,
      required this.label,
      this.onTap,
      this.primary = true,
      this.fontSize = 16,
      this.width});

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: widget.width,
            constraints:
                const BoxConstraints(minHeight: GoTheme.touch, minWidth: 88),
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.primary
                    ? [GoTheme.kayaHoney, GoTheme.kayaDeep]
                    : [GoTheme.clamshell, const Color(0xFFEFE6D8)],
              ),
              border: Border.all(
                  color: widget.primary
                      ? GoTheme.kayaDeep
                      : GoTheme.carved,
                  width: 1.2),
              boxShadow: _down
                  ? [
                      const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                          spreadRadius: -1),
                    ]
                  : [
                      const BoxShadow(
                          color: GoTheme.woodShadow,
                          blurRadius: 10,
                          offset: Offset(0, 5)),
                      const BoxShadow(
                          color: Colors.white70,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                          spreadRadius: -1),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(widget.label,
                style: GoTheme.body(widget.fontSize,
                    color: widget.primary
                        ? GoTheme.clamshell
                        : GoTheme.sumi,
                    weight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

/// Round wooden disc button (pass / undo / resign / pause).
class WoodDisc extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;
  const WoodDisc(
      {super.key,
      required this.icon,
      required this.label,
      this.onTap,
      this.tint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: tint != null
                      ? [tint!.withValues(alpha: 0.9), tint!]
                      : [GoTheme.kayaHoney, GoTheme.kayaDeep],
                ),
                border: Border.all(color: GoTheme.kayaDeep, width: 1.4),
                boxShadow: const [
                  BoxShadow(
                      color: GoTheme.woodShadow,
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Icon(icon,
                  color: GoTheme.clamshell, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: GoTheme.label(11)),
          ],
        ),
      ),
    );
  }
}

class WoodCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const WoodCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GoTheme.clamshell,
        borderRadius: GoTheme.cardRadius,
        border: Border.all(color: GoTheme.carved, width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: GoTheme.woodShadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class SectionHead extends StatelessWidget {
  final String title;
  final String? kanji;
  const SectionHead({super.key, required this.title, this.kanji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: GoTheme.kayaDeep),
        const SizedBox(width: 8),
        Text(title,
            style:
                GoTheme.body(15, weight: FontWeight.w600, color: GoTheme.sumi)),
        if (kanji != null) ...[
          const SizedBox(width: 8),
          Text(kanji!,
              style: GoTheme.body(13, color: GoTheme.inkGrey)),
        ],
      ],
    );
  }
}

/// Segmented control carved in light wood.
class WoodSegmented<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T current;
  final ValueChanged<T> onChanged;
  const WoodSegmented(
      {super.key,
      required this.values,
      required this.labels,
      required this.current,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4D4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GoTheme.carved),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: -1),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(values[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: values[i] == current
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [GoTheme.kayaHoney, GoTheme.kayaDeep])
                        : null,
                    boxShadow: values[i] == current
                        ? const [
                            BoxShadow(
                                color: GoTheme.woodShadow,
                                blurRadius: 6,
                                offset: Offset(0, 3))
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(labels[i],
                      style: GoTheme.label(13,
                          color: values[i] == current
                              ? GoTheme.clamshell
                              : GoTheme.sumi)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WoodToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const WoodToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? GoTheme.kayaDeep : const Color(0xFFD9CDBB),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
                spreadRadius: -1),
          ],
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD9A85E), Color(0xFF9A5F14)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black38, blurRadius: 3, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class WoodSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const WoodSlider(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: GoTheme.kayaHoney,
        inactiveTrackColor: const Color(0xFFE4D6BF),
        thumbShape: const _WoodThumb(),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
    );
  }
}

class _WoodThumb extends SliderComponentShape {
  const _WoodThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final c = context.canvas;
    c.drawCircle(
        center + const Offset(1, 2), 13, Paint()..color = Colors.black26);
    c.drawCircle(
        center,
        13,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9A85E), Color(0xFF8A5410)],
          ).createShader(Rect.fromCircle(center: center, radius: 13)));
    c.drawCircle(center + const Offset(-4, -4), 4,
        Paint()..color = Colors.white.withValues(alpha: 0.35));
  }
}

/// Stepper for handicap (0–9).
class WoodStepper extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const WoodStepper(
      {super.key,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData ic, VoidCallback? fn) => GestureDetector(
          onTap: fn,
          child: Opacity(
            opacity: fn == null ? 0.35 : 1,
            child: Container(
              width: GoTheme.touch,
              height: GoTheme.touch,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoTheme.clamshell,
                border: Border.all(color: GoTheme.kayaDeep, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                      color: GoTheme.woodShadow,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Icon(ic, color: GoTheme.kayaDeep, size: 20),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove,
            value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 56,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: GoTheme.counter(20)),
        ),
        btn(Icons.add, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

/// Miniature physical stones for the capture bowls.
class MiniStone extends StatelessWidget {
  final bool black;
  final double size;
  const MiniStone({super.key, required this.black, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: black
              ? [GoTheme.slateTop, GoTheme.slateDeep]
              : [Colors.white, const Color(0xFFE4DCCB)],
        ),
        boxShadow: const [
          BoxShadow(
              color: GoTheme.stoneShadow, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
