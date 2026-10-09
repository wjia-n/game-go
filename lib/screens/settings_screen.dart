import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../engine/bot.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/wood.dart';

/// Settings — 設定: stacked light-wood cards for audio, game rules and bot.
class SettingsScreen extends StatelessWidget {
  final GoSettings settings;
  final SoundService sound;
  final VoidCallback onBack;

  const SettingsScreen(
      {super.key,
      required this.settings,
      required this.sound,
      required this.onBack});

  void _audio(GoSettings st) {
    sound.applySettings(
        sfxOn: st.sfxOn,
        musicOn: st.musicOn,
        sfxVolume: st.sfxVolume,
        musicVolume: st.musicVolume);
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.arrow_back_rounded,
                          color: GoTheme.kayaDeep),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Settings', style: GoTheme.display(26)),
                  const SizedBox(width: 8),
                  Text('設定',
                      style: GoTheme.body(15,
                          color: GoTheme.inkGrey)),
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
                    const Divider(color: GoTheme.carved, height: 20),
                    _toggleRow('Sound effects', 'stone clicks & chimes',
                        st.sfxOn, (v) {
                      st.update(() => st.sfxOn = v);
                      _audio(st);
                      sound.playTap();
                    }),
                    const SizedBox(height: 8),
                    Text('Music volume',
                        style: GoTheme.label(13)),
                    WoodSlider(
                        value: st.musicVolume,
                        onChanged: (v) {
                          st.update(() => st.musicVolume = v);
                          _audio(st);
                        }),
                    Text('Effects volume',
                        style: GoTheme.label(13)),
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
                    const Divider(color: GoTheme.carved, height: 20),
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
                    const Divider(color: GoTheme.carved, height: 20),
                    _toggleRow('Board coordinates', 'A–T · 1–19 labels',
                        st.showCoordinates, (v) {
                      sound.playTap();
                      st.update(() => st.showCoordinates = v);
                    }),
                    const Divider(color: GoTheme.carved, height: 20),
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
                    WoodSegmented<BotDifficulty>(
                      values: BotDifficulty.values,
                      labels: const ['Easy', 'Medium', 'Hard'],
                      current: st.botDifficulty,
                      onChanged: (v) {
                        sound.playTap();
                        st.update(() => st.botDifficulty = v);
                      },
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

  Widget _toggleRow(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      GoTheme.body(14, weight: FontWeight.w600)),
              Text(sub, style: GoTheme.label(11)),
            ],
          ),
        ),
        WoodToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
