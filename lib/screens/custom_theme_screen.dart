import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/wood.dart';

/// Custom theme creator (PRO): pick zen palette swatches for background,
/// cards, accents and text, with a live preview. Saved as theme 'custom'.
class CustomThemeScreen extends StatefulWidget {
  final GoSettings settings;
  final SoundService audio;
  final VoidCallback onOpenPro;
  final VoidCallback onBack;

  const CustomThemeScreen({
    super.key,
    required this.settings,
    required this.audio,
    required this.onOpenPro,
    required this.onBack,
  });

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  late Color _bg, _card, _accent, _accentDeep, _text;
  late bool _dark;

  static const _swatches = [
    Color(0xFFF5EFEB),
    Color(0xFFF8F4E4),
    Color(0xFFF1F3E8),
    Color(0xFFF4F4F2),
    Color(0xFFEFE3C8),
    Color(0xFFF9F0EE),
    Color(0xFFEEF2F3),
    Color(0xFFEFF0E8),
    Color(0xFF2A2622),
    Color(0xFF1E2430),
    Color(0xFF2E332A),
    Color(0xFF3A2E30),
  ];
  static const _accents = [
    Color(0xFF865307),
    Color(0xFFC88A3F),
    Color(0xFF5C6E2A),
    Color(0xFF2B2B2B),
    Color(0xFF96555A),
    Color(0xFF45686D),
    Color(0xFF55663F),
    Color(0xFF96521F),
    Color(0xFF4A5A2E),
    Color(0xFF7A5E22),
    Color(0xFFE0BE7E),
    Color(0xFFD89A52),
  ];
  static const _texts = [
    Color(0xFF33302E),
    Color(0xFF1A1A1A),
    Color(0xFF2E332A),
    Color(0xFF3A2E30),
    Color(0xFF2A3436),
    Color(0xFF33291A),
    Color(0xFFF5EDE0),
    Color(0xFFF0EAD9),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.settings.customTheme;
    final base = widget.settings.activeTheme;
    _bg = c?.tatami ?? base.tatami;
    _card = c?.clamshell ?? base.clamshell;
    _accent = c?.accent ?? base.kayaHoney;
    _accentDeep = c?.accentDeep ?? base.kayaDeep;
    _text = c?.text ?? base.sumi;
    _dark = c?.dark ?? false;
  }

  CustomThemeDef _draft() => CustomThemeDef(
        tatami: _bg,
        clamshell: _card,
        accent: _accent,
        accentDeep: _accentDeep,
        text: _text,
        dark: _dark,
      );

  void _save() {
    widget.audio.playStart();
    widget.settings.update(() {
      widget.settings.customTheme = _draft();
      widget.settings.themeId = 'custom';
    });
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    GoTheme.use(widget.settings.activeTheme);
    if (!widget.settings.isPro) {
      return _ProGate(
          audio: widget.audio,
          onOpenPro: widget.onOpenPro,
          onBack: widget.onBack);
    }
    final preview = _draft().toThemeDef();
    return Scaffold(
      backgroundColor: preview.tatami,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: preview.kayaDeep),
          onPressed: () {
            widget.audio.playTap();
            widget.onBack();
          },
        ),
        title: Text('Custom theme', style: preview.display(22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // live preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: preview.clamshell,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: preview.carved),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preview', style: preview.display(18)),
                  const SizedBox(height: 6),
                  Text('The stones wait patiently.',
                      style: preview.body(14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(colors: [
                            preview.kayaHoney,
                            preview.kayaDeep
                          ]),
                        ),
                        child: Text('Play',
                            style: preview.body(14,
                                color: preview.clamshell,
                                weight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Text('12 captures',
                          style: preview.counter(14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SwatchRow(
                title: 'Background',
                colors: _swatches,
                current: _bg,
                onPick: (c) => setState(() => _bg = c)),
            _SwatchRow(
                title: 'Cards',
                colors: _swatches,
                current: _card,
                onPick: (c) => setState(() => _card = c)),
            _SwatchRow(
                title: 'Accent',
                colors: _accents,
                current: _accent,
                onPick: (c) => setState(() => _accent = c)),
            _SwatchRow(
                title: 'Deep accent',
                colors: _accents,
                current: _accentDeep,
                onPick: (c) => setState(() => _accentDeep = c)),
            _SwatchRow(
                title: 'Text',
                colors: _texts,
                current: _text,
                onPick: (c) => setState(() => _text = c)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text('Dark cards',
                        style: preview.body(14, weight: FontWeight.w600))),
                WoodToggle(
                    value: _dark,
                    onChanged: (v) => setState(() => _dark = v)),
              ],
            ),
            const SizedBox(height: 22),
            Center(
              child: WoodButton(
                  label: 'Save my theme', width: 220, onTap: _save),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final Color current;
  final ValueChanged<Color> onPick;
  const _SwatchRow(
      {required this.title,
      required this.colors,
      required this.current,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoTheme.label(13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in colors)
                GestureDetector(
                  onTap: () => onPick(c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: c == current
                            ? GoTheme.kayaDeep
                            : GoTheme.carved,
                        width: c == current ? 3 : 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProGate extends StatelessWidget {
  final SoundService audio;
  final VoidCallback onOpenPro;
  final VoidCallback onBack;
  const _ProGate(
      {required this.audio, required this.onOpenPro, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoTheme.tatami,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: GoTheme.kayaDeep),
          onPressed: () {
            audio.playTap();
            onBack();
          },
        ),
        title: Text('Custom theme', style: GoTheme.display(22)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: WoodCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✦', style: GoTheme.display(40)),
                const SizedBox(height: 8),
                Text('A PRO craft',
                    style: GoTheme.display(20), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Design your own dojo colors with the custom theme creator — exclusive to Go PRO.',
                  style: GoTheme.body(14, color: GoTheme.inkGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                WoodButton(
                    label: 'See Go PRO',
                    width: 220,
                    onTap: () {
                      audio.playTap();
                      onOpenPro();
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
