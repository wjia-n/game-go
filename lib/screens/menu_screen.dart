import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../engine/bot.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/wood.dart';

/// Main menu: title block → board-size cards → mode cards → settings gear →
/// big round wooden Play button. Portrait, serene negative space.
class MenuScreen extends StatefulWidget {
  final GoSettings settings;
  final SoundService sound;
  final GameState game;
  final bool hasSave;
  final VoidCallback onPlay;
  final VoidCallback onResume;
  final VoidCallback onOpenSettings;

  const MenuScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.game,
    required this.hasSave,
    required this.onPlay,
    required this.onResume,
    required this.onOpenSettings,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _size = 9;
  GameMode _mode = GameMode.vsBot;

  @override
  void initState() {
    super.initState();
    widget.sound.setMusicMode('menu');
  }

  void _start() {
    widget.sound.playStart();
    widget.game.newGame(
      boardSize: _size,
      gameMode: _mode,
      botDifficulty: widget.settings.botDifficulty,
      botPlays: widget.settings.botColor,
      handicapStones: _mode == GameMode.twoPlayer ? widget.settings.handicap : 0,
    );
    widget.onPlay();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.settings;
    return Scaffold(
      backgroundColor: GoTheme.tatami,
      body: SafeArea(
        child: Stack(
          children: [
            // faint 囲碁 watermark
            Positioned(
              right: -30,
              top: 60,
              child: Opacity(
                opacity: 0.05,
                child: Text('囲碁',
                    style: GoTheme.display(200, weight: FontWeight.w700)),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _iconBtn(Icons.settings_outlined, () {
                      widget.sound.playTap();
                      widget.onOpenSettings();
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                // title block
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          MiniStone(black: true, size: 30),
                          SizedBox(width: 10),
                          MiniStone(black: false, size: 30),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Go', style: GoTheme.display(52)),
                      Text('囲碁',
                          style: GoTheme.body(18,
                              color: GoTheme.inkGrey)),
                      const SizedBox(height: 4),
                      Text('the ancient game of territory',
                          style: GoTheme.body(14,
                              color: GoTheme.inkGrey)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (widget.hasSave) ...[
                  WoodButton(
                      label: 'Resume last game',
                      primary: false,
                      width: double.infinity,
                      onTap: () {
                        widget.sound.playTap();
                        widget.onResume();
                      }),
                  const SizedBox(height: 12),
                ],
                const SectionHead(title: 'Board', kanji: '盤'),
                const SizedBox(height: 8),
                WoodSegmented<int>(
                  values: const [9, 13, 19],
                  labels: const ['9 × 9', '13 × 13', '19 × 19'],
                  current: _size,
                  onChanged: (v) {
                    widget.sound.playTap();
                    setState(() => _size = v);
                    st.update(() =>
                        st.komi = v == 9 ? 4.5 : v == 13 ? 5.5 : 6.5);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      _size == 9
                          ? 'beginner · quick games'
                          : _size == 13
                              ? 'intermediate · a quiet afternoon'
                              : 'standard · the full mountain',
                      style: GoTheme.label(12)),
                ),
                const SizedBox(height: 18),
                const SectionHead(title: 'Players', kanji: '対局'),
                const SizedBox(height: 8),
                WoodSegmented<GameMode>(
                  values: const [GameMode.vsBot, GameMode.twoPlayer],
                  labels: const ['Vs Bot', 'Two Players'],
                  current: _mode,
                  onChanged: (v) {
                    widget.sound.playTap();
                    setState(() => _mode = v);
                  },
                ),
                if (_mode == GameMode.vsBot) ...[
                  const SizedBox(height: 12),
                  const SectionHead(title: 'Bot strength', kanji: '強さ'),
                  const SizedBox(height: 8),
                  WoodSegmented<BotDifficulty>(
                    values: BotDifficulty.values,
                    labels: const ['Easy', 'Medium', 'Hard'],
                    current: st.botDifficulty,
                    onChanged: (v) {
                      widget.sound.playTap();
                      st.update(() => st.botDifficulty = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  const SectionHead(title: 'Bot plays', kanji: '手合'),
                  const SizedBox(height: 8),
                  WoodSegmented<int>(
                    values: const [1, 2],
                    labels: const ['Black (first)', 'White'],
                    current: st.botColor,
                    onChanged: (v) {
                      widget.sound.playTap();
                      st.update(() => st.botColor = v);
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const SectionHead(title: 'Handicap stones', kanji: '置石'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      WoodStepper(
                          value: st.handicap,
                          min: 0,
                          max: 9,
                          onChanged: (v) {
                            widget.sound.playTap();
                            st.update(() => st.handicap = v);
                          }),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              st.handicap >= 2
                                  ? 'black places ${st.handicap}, komi 0.5'
                                  : 'even game',
                              style: GoTheme.label(12))),
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                // the big round wooden Play button
                Center(
                  child: GestureDetector(
                    onTap: _start,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [GoTheme.kayaHoney, GoTheme.kayaDeep],
                        ),
                        border: Border.all(
                            color: GoTheme.kayaDeep, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: GoTheme.woodShadow,
                              blurRadius: 18,
                              offset: Offset(0, 9)),
                          BoxShadow(
                              color: Colors.white70,
                              blurRadius: 2,
                              offset: Offset(0, 2),
                              spreadRadius: -2),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          size: 56, color: GoTheme.clamshell),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                    child: Text('begin',
                        style: GoTheme.body(14,
                            color: GoTheme.inkGrey))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: GoTheme.touch,
        height: GoTheme.touch,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GoTheme.clamshell,
          border: Border.all(color: GoTheme.carved),
          boxShadow: const [
            BoxShadow(
                color: GoTheme.woodShadow,
                blurRadius: 6,
                offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: GoTheme.kayaDeep, size: 22),
      ),
    );
  }
}
