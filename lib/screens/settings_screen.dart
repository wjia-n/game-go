import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../engine/bot.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/name_field.dart';
import '../widgets/wood.dart';

/// Settings — 設定: sound, rules, bot, and player names.
class SettingsScreen extends StatelessWidget {
  final GoSettings settings;
  final SoundService sound;
  final VoidCallback onBack;
  final VoidCallback onOpenPro;

  const SettingsScreen(
      {super.key,
      required this.settings,
      required this.sound,
      required this.onBack,
      required this.onOpenPro});

  void _audio(GoSettings st) {
    sound.configure(
        sfxOn: st.sfxOn,
        musicOn: st.musicOn,
        sfxVolume: st.sfxVolume,
        musicVolume: st.musicVolume);
  }

  @override
  Widget build(BuildContext context) {
    GoTheme.use(settings.activeTheme);
    final st = settings;
    return ListenableBuilder(
      listenable: st,
      builder: (ctx, _) => Scaffold(
        backgroundColor: GoTheme.tatami,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      sound.playTap();
                      onBack();
                    },
                    child: Container(
                      width: GoTheme.touch,
                      height: GoTheme.touch,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GoTheme.clamshell,
                        border: Border.all(color: GoTheme.carved),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: GoTheme.kayaDeep),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Settings', style: GoTheme.display(26)),
                  const SizedBox(width: 8),
                  Text('設定',
                      style: GoTheme.body(15, color: GoTheme.inkGrey)),
                  const Spacer(),
                  if (!st.isPro)
                    GestureDetector(
                      onTap: () {
                        sound.playTap();
                        onOpenPro();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(colors: [
                            GoTheme.kayaHoney,
                            GoTheme.kayaDeep
                          ]),
                        ),
                        child: Text('✦ GO PRO',
                            style: GoTheme.label(13,
                                color: GoTheme.clamshell)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              WoodCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHead(title: 'Sound', kanji: '音'),
                    const SizedBox(height: 12),
                    _toggleRow('Music', 'ambient koto & room tone', st.musicOn,
                        (v) {
                      sound.playTap();
                      st.update(() => st.musicOn = v);
                      _audio(st);
                    }),
                    Divider(color: GoTheme.carved, height: 20),
                    _toggleRow('Sound effects', 'stone clicks & chimes',
                        st.sfxOn, (v) {
                      st.update(() => st.sfxOn = v);
                      _audio(st);
                      sound.playTap();
                    }),
                    const SizedBox(height: 8),
                    Text('Music volume', style: GoTheme.label(13)),
                    WoodSlider(
                        value: st.musicVolume,
                        onChanged: (v) {
                          st.update(() => st.musicVolume = v);
                          _audio(st);
                        }),
                    Text('Effects volume', style: GoTheme.label(13)),
                    WoodSlider(
                        value: st.sfxVolume,
                        onChanged: (v) {
                          st.update(() => st.sfxVolume = v);
                          _audio(st);
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WoodCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHead(title: 'Players', kanji: '名前'),
                    const SizedBox(height: 12),
                    NameField(
                        label: 'Your name (vs bot)',
                        value: st.humanName,
                        fill: GoTheme.tatami,
                        onInteract: () => sound.playTap(),
                        onCommit: (v) =>
                            st.update(() => st.humanName = v)),
                    const SizedBox(height: 8),
                    NameField(
                        label: 'Bot name',
                        value: st.botName,
                        fill: GoTheme.tatami,
                        onInteract: () => sound.playTap(),
                        onCommit: (v) => st.update(() => st.botName = v)),
                    const SizedBox(height: 8),
                    NameField(
                        label: 'Player 1 (2P)',
                        value: st.p1Name,
                        fill: GoTheme.tatami,
                        onInteract: () => sound.playTap(),
                        onCommit: (v) => st.update(() => st.p1Name = v)),
                    const SizedBox(height: 8),
                    NameField(
                        label: 'Player 2 (2P)',
                        value: st.p2Name,
                        fill: GoTheme.tatami,
                        onInteract: () => sound.playTap(),
                        onCommit: (v) => st.update(() => st.p2Name = v)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WoodCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHead(title: 'Rules', kanji: '規則'),
                    const SizedBox(height: 12),
                    Text('Komi (white compensation)',
                        style: GoTheme.label(13)),
                    const SizedBox(height: 6),
                    WoodSegmented<double>(
                      values: const [4.5, 5.5, 6.5],
                      labels: const ['4.5', '5.5', '6.5'],
                      current: st.komi,
                      onChanged: (v) {
                        sound.playTap();
                        st.update(() => st.komi = v);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: WoodSlider(
                              value: st.komi / 10,
                              onChanged: (v) => st.update(() =>
                                  st.komi =
                                      ((v * 10 * 2).round() / 2)
                                          .clamp(0.0, 10.0))),
                        ),
                        SizedBox(
                            width: 52,
                            child: Text(st.komi.toStringAsFixed(1),
                                textAlign: TextAlign.end,
                                style: GoTheme.counter(15))),
                      ],
                    ),
                    Text('half-point steps · whole numbers allow draws',
                        style: GoTheme.label(11)),
                    Divider(color: GoTheme.carved, height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: Text('Handicap stones',
                                style: GoTheme.label(13))),
                        WoodStepper(
                            value: st.handicap,
                            min: 0,
                            max: 9,
                            onChanged: (v) {
                              sound.playTap();
                              st.update(() => st.handicap = v);
                            }),
                      ],
                    ),
                    Text('two-player only · sets komi to 0.5',
                        style: GoTheme.label(11)),
                    Divider(color: GoTheme.carved, height: 20),
                    _toggleRow('Board coordinates', 'A–T · 1–19 labels',
                        st.showCoordinates, (v) {
                      sound.playTap();
                      st.update(() => st.showCoordinates = v);
                    }),
                    Divider(color: GoTheme.carved, height: 20),
                    _toggleRow('Confirm before pass', 'avoids slips',
                        st.confirmPass, (v) {
                      sound.playTap();
                      st.update(() => st.confirmPass = v);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WoodCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHead(title: 'Bot', kanji: '相手'),
                    const SizedBox(height: 12),
                    Text('Strength', style: GoTheme.label(13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0;
                            i < BotDifficulty.values.length;
                            i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                              child: _difficultyChip(
                                  BotDifficulty.values[i])),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Bot plays', style: GoTheme.label(13)),
                    const SizedBox(height: 6),
                    WoodSegmented<int>(
                      values: const [1, 2],
                      labels: const ['Black (first)', 'White'],
                      current: st.botColor,
                      onChanged: (v) {
                        sound.playTap();
                        st.update(() => st.botColor = v);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text('applies to the next game',
                        style: GoTheme.label(11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyChip(BotDifficulty d) {
    final st = settings;
    final locked = d == BotDifficulty.hard && !st.isPro;
    final selected = st.botDifficulty == d;
    final label = d == BotDifficulty.easy
        ? 'Easy'
        : d == BotDifficulty.medium
            ? 'Medium'
            : 'Hard';
    return GestureDetector(
      onTap: () {
        sound.playTap();
        if (locked) {
          onOpenPro();
          return;
        }
        st.update(() => st.botDifficulty = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? LinearGradient(
                  colors: [GoTheme.kayaHoney, GoTheme.kayaDeep])
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
                    color:
                        selected ? GoTheme.clamshell : GoTheme.inkGrey),
              ),
            Text(label,
                style: GoTheme.label(13,
                    color:
                        selected ? GoTheme.clamshell : GoTheme.sumi)),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoTheme.body(14, weight: FontWeight.w600)),
              Text(sub, style: GoTheme.label(11)),
            ],
          ),
        ),
        WoodToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
