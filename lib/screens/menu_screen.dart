import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../engine/bot.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/look_picker.dart';
import '../widgets/name_field.dart';
import '../widgets/wood.dart';

/// Main menu: logo + title → board-size → mode → names → difficulty →
/// theme/stone/wood pickers → big wooden Play button. Portrait, serene.
class MenuScreen extends StatefulWidget {
  final GoSettings settings;
  final SoundService sound;
  final GameState game;
  final bool hasSave;
  final VoidCallback onPlay;
  final VoidCallback onResume;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPro;
  final VoidCallback onOpenCustomTheme;

  const MenuScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.game,
    required this.hasSave,
    required this.onPlay,
    required this.onResume,
    required this.onOpenSettings,
    required this.onOpenPro,
    required this.onOpenCustomTheme,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _size = 9;
  GameMode _mode = GameMode.vsBot;

  GoSettings get st => widget.settings;

  void _start() {
    widget.sound.playStart();
    widget.game.newGame(
      boardSize: _size,
      gameMode: _mode,
      botDifficulty: st.botDifficulty,
      botPlays: st.botColor,
      handicapStones: _mode == GameMode.twoPlayer ? st.handicap : 0,
    );
    widget.onPlay();
  }

  void _pickLocked() {
    widget.sound.playTap();
    widget.onOpenPro();
  }

  @override
  Widget build(BuildContext context) {
    GoTheme.use(st.activeTheme);
    BoardLook.use(wood: st.activeWood, stone: st.activeStone);
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
                    if (!st.isPro)
                      _proChip(),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.settings_outlined, () {
                      widget.sound.playTap();
                      widget.onOpenSettings();
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                // title block with the game logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border:
                              Border.all(color: GoTheme.kayaDeep, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: GoTheme.woodShadow,
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/go_logo.png',
                            fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 10),
                      Text('Go', style: GoTheme.display(48)),
                      Text('囲碁',
                          style: GoTheme.body(17, color: GoTheme.inkGrey)),
                      const SizedBox(height: 2),
                      Text('the ancient game of territory',
                          style: GoTheme.body(13, color: GoTheme.inkGrey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 12),
                if (_mode == GameMode.vsBot) ...[
                  NameField(
                      label: 'Your name',
                      value: st.humanName,
                      onInteract: () => widget.sound.playTap(),
                      onCommit: (v) =>
                          st.update(() => st.humanName = v)),
                  const SizedBox(height: 8),
                  NameField(
                      label: 'Bot name',
                      value: st.botName,
                      onInteract: () => widget.sound.playTap(),
                      onCommit: (v) => st.update(() => st.botName = v)),
                  const SizedBox(height: 14),
                  const SectionHead(title: 'Bot strength', kanji: '強さ'),
                  const SizedBox(height: 8),
                  _difficultyRow(),
                  const SizedBox(height: 14),
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
                  NameField(
                      label: 'Black · player 1',
                      value: st.p1Name,
                      onInteract: () => widget.sound.playTap(),
                      onCommit: (v) => st.update(() => st.p1Name = v)),
                  const SizedBox(height: 8),
                  NameField(
                      label: 'White · player 2',
                      value: st.p2Name,
                      onInteract: () => widget.sound.playTap(),
                      onCommit: (v) => st.update(() => st.p2Name = v)),
                  const SizedBox(height: 14),
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
                const SizedBox(height: 20),
                LookPicker(
                  title: 'Theme',
                  kanji: '色',
                  options: [
                    for (final t in GoThemes.all)
                      LookOption(
                          id: t.id,
                          name: t.name,
                          preview: t.kayaDeep,
                          locked: t.isPro && !st.isPro),
                    if (st.customTheme != null || st.isPro)
                      LookOption(
                          id: 'custom',
                          name: 'My Theme',
                          preview: st.customTheme?.accent ??
                              GoTheme.kayaDeep,
                          locked: !st.isPro),
                  ],
                  current: st.themeId,
                  onPick: (id) {
                    if (id == 'custom' && st.customTheme == null) {
                      widget.onOpenCustomTheme();
                      return;
                    }
                    widget.sound.playTap();
                    st.update(() => st.themeId = id);
                  },
                  onUnlock: _pickLocked,
                  trailing: TextButton(
                    onPressed: () {
                      widget.sound.playTap();
                      widget.onOpenCustomTheme();
                    },
                    child: Text('customize',
                        style: GoTheme.label(12, color: GoTheme.kayaDeep)),
                  ),
                ),
                const SizedBox(height: 14),
                LookPicker(
                  title: 'Stones',
                  kanji: '石',
                  options: [
                    for (final s in StoneStyles.all)
                      LookOption(
                          id: s.id,
                          name: s.name,
                          preview: s.blackDeep,
                          locked: s.isPro && !st.isPro),
                  ],
                  current: st.stoneId,
                  onPick: (id) {
                    widget.sound.playTap();
                    st.update(() => st.stoneId = id);
                  },
                  onUnlock: _pickLocked,
                ),
                const SizedBox(height: 14),
                LookPicker(
                  title: 'Board wood',
                  kanji: '木',
                  options: [
                    for (final w in Woods.all)
                      LookOption(
                          id: w.id,
                          name: w.name,
                          preview: w.mid,
                          locked: w.isPro && !st.isPro),
                  ],
                  current: st.woodId,
                  onPick: (id) {
                    widget.sound.playTap();
                    st.update(() => st.woodId = id);
                  },
                  onUnlock: _pickLocked,
                ),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [GoTheme.kayaHoney, GoTheme.kayaDeep],
                        ),
                        border:
                            Border.all(color: GoTheme.kayaDeep, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: GoTheme.woodShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 9)),
                          BoxShadow(
                              color: Colors.white.withValues(alpha: 0.45),
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                              spreadRadius: -2),
                        ],
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          size: 56, color: GoTheme.clamshell),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                    child: Text('begin',
                        style:
                            GoTheme.body(14, color: GoTheme.inkGrey))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _proChip() {
    return GestureDetector(
      onTap: () {
        widget.sound.playTap();
        widget.onOpenPro();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
              colors: [GoTheme.kayaHoney, GoTheme.kayaDeep]),
          boxShadow: [
            BoxShadow(
                color: GoTheme.woodShadow,
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Text('✦ GO PRO',
            style: GoTheme.label(13, color: GoTheme.clamshell)),
      ),
    );
  }

  Widget _difficultyRow() {
    return Row(
      children: [
        for (var i = 0; i < BotDifficulty.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _difficultyChip(BotDifficulty.values[i])),
        ],
      ],
    );
  }

  Widget _difficultyChip(BotDifficulty d) {
    final locked = d == BotDifficulty.hard && !st.isPro;
    final selected = st.botDifficulty == d;
    final label =
        d == BotDifficulty.easy ? 'Easy' : d == BotDifficulty.medium ? 'Medium' : 'Hard';
    return GestureDetector(
      onTap: () {
        widget.sound.playTap();
        if (locked) {
          widget.onOpenPro();
          return;
        }
        st.update(() => st.botDifficulty = d);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? LinearGradient(colors: [GoTheme.kayaHoney, GoTheme.kayaDeep])
              : null,
          color: selected ? null : GoTheme.clamshell,
          border: Border.all(
              color: selected ? GoTheme.kayaDeep : GoTheme.carved,
              width: selected ? 1.6 : 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.lock_outline_rounded,
                    size: 14,
                    color: selected ? GoTheme.clamshell : GoTheme.inkGrey),
              ),
            Text(label,
                style: GoTheme.label(13,
                    color: selected
                        ? GoTheme.clamshell
                        : GoTheme.sumi)),
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
          boxShadow: [
            BoxShadow(
                color: GoTheme.woodShadow,
                blurRadius: 6,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: GoTheme.kayaDeep, size: 22),
      ),
    );
  }
}
