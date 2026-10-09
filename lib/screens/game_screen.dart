import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/goban.dart';
import '../widgets/wood.dart';

/// Game board screen: per-side trays (nameplates + capture bowls + thinking
/// narration), 1:1 goban in the active wood/stone styles, Pass / Undo /
/// Resign discs at the bottom.
///
/// Bot turns are fully visible: the active side's tray narrates "thinking…"
/// with animated dots, then the stone drops with animation + placed-stone
/// sound. Nothing ever silently auto-plays.
class GameScreen extends StatelessWidget {
  final GameState game;
  final GoSettings settings;
  final SoundService sound;
  final VoidCallback onPauseSettings;
  final VoidCallback onQuitToMenu;

  /// When true the finished board is shown read-only with a results button.
  final bool reviewMode;
  final VoidCallback? onReviewDone;

  const GameScreen({
    super.key,
    required this.game,
    required this.settings,
    required this.sound,
    required this.onPauseSettings,
    required this.onQuitToMenu,
    this.reviewMode = false,
    this.onReviewDone,
  });

  @override
  Widget build(BuildContext context) {
    GoTheme.use(settings.activeTheme);
    BoardLook.use(wood: settings.activeWood, stone: settings.activeStone);
    return ListenableBuilder(
      listenable: game,
      builder: (ctx, _) => Scaffold(
        backgroundColor: GoTheme.tatami,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(ctx),
              _trays(ctx),
              _narrationLine(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: game.phase == GamePhase.markDead || reviewMode
                          ? _reviewBoard()
                          : GobanBoard(
                              board: game.board,
                              size: game.size,
                              lastMove: game.lastMove,
                              invalidAt: game.invalidAt,
                              dead: const {},
                              territory: const {},
                              showCoordinates: settings.showCoordinates,
                              onTap: game.tapPoint,
                            ),
                    ),
                  ),
                ),
              ),
              _bottomBar(ctx),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _roundIcon(Icons.pause_rounded, () => _pauseDialog(ctx)),
          const Spacer(),
          Text('Go · ${game.size}×${game.size}',
              style: GoTheme.body(15, weight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('囲碁', style: GoTheme.body(13, color: GoTheme.inkGrey)),
          const Spacer(),
          _roundIcon(Icons.flag_outlined, () => _resignDialog(ctx)),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        sound.playTap();
        onTap();
      },
      child: Container(
        width: GoTheme.touch,
        height: GoTheme.touch,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GoTheme.clamshell,
          border: Border.all(color: GoTheme.carved),
          boxShadow: [
            BoxShadow(
                color: GoTheme.woodShadow, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: GoTheme.kayaDeep, size: 22),
      ),
    );
  }

  /// Per-side trays: each player side owns its nameplate, capture bowl and
  /// thinking narration. The active side highlights.
  Widget _trays(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(child: _tray(ctx, 1, game.capByBlack)),
          const SizedBox(width: 10),
          Expanded(child: _tray(ctx, 2, game.capByWhite)),
        ],
      ),
    );
  }

  Widget _tray(BuildContext ctx, int color, int captures) {
    final active =
        game.turn == color && game.phase == GamePhase.play && !game.over;
    final thinking = active &&
        game.mode == GameMode.vsBot &&
        game.botThinking &&
        game.turn == game.botColor;
    final name = game.nameFor(color);
    final role = game.mode == GameMode.vsBot
        ? (color == game.botColor ? 'bot' : 'you')
        : (color == 1 ? 'black' : 'white');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: GoTheme.clamshell,
        borderRadius: GoTheme.cardRadius,
        border: Border.all(
            color: active ? GoTheme.kayaDeep : GoTheme.carved,
            width: active ? 2 : 1.2),
        boxShadow: [
          if (active)
            BoxShadow(
                color: GoTheme.woodShadow,
                blurRadius: 10,
                offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          MiniStone(black: color == 1, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _renameDialog(ctx, color, name),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(name,
                            style: GoTheme.body(14,
                                weight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.edit_outlined,
                          size: 12, color: GoTheme.inkGrey),
                    ],
                  ),
                ),
                thinking
                    ? _ThinkingDots(color: color)
                    : Text(role, style: GoTheme.label(11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$captures', style: GoTheme.counter(17)),
              Text('captured', style: GoTheme.label(10)),
            ],
          ),
        ],
      ),
    );
  }

  void _renameDialog(BuildContext ctx, int color, String current) {
    final ctrl = TextEditingController(text: current);
    sound.playTap();
    showDialog(
      context: ctx,
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        child: WoodCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rename player', style: GoTheme.display(18)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: GoTheme.tatami,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GoTheme.carved),
                ),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoTheme.body(15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLength: 16,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(d).pop(),
                    child: Text('Cancel',
                        style: GoTheme.label(14, color: GoTheme.inkGrey)),
                  ),
                  const SizedBox(width: 6),
                  WoodButton(
                    label: 'Save',
                    fontSize: 14,
                    onTap: () {
                      final v = ctrl.text.trim();
                      if (v.isNotEmpty) {
                        sound.playTap();
                        settings.update(() {
                          if (game.mode == GameMode.vsBot) {
                            if (color == game.botColor) {
                              settings.botName = v;
                            } else {
                              settings.humanName = v;
                            }
                          } else {
                            if (color == 1) {
                              settings.p1Name = v;
                            } else {
                              settings.p2Name = v;
                            }
                          }
                        });
                      }
                      Navigator.of(d).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Narration line: the engine's own account of the game ("Kishi plays D4",
  /// "Kishi is thinking…"). Never empty during play.
  Widget _narrationLine() {
    String text;
    if (reviewMode) {
      text = game.scoreLine;
    } else if (game.phase == GamePhase.markDead) {
      text = 'tap stone groups to toggle them dead, then count the score';
    } else {
      text = game.narration.isEmpty
          ? 'move ${game.moves + 1} · ${game.turn == 1 ? 'black' : 'white'} to play'
          : game.narration;
      if (game.passes == 1 && game.phase == GamePhase.play) {
        text += ' · one pass so far';
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoTheme.body(13, color: GoTheme.inkGrey)),
    );
  }

  Widget _reviewBoard() {
    // scoring review: dead groups hollowed, territory dotted
    return GobanBoard(
      board: game.board,
      size: game.size,
      lastMove: -1,
      invalidAt: -1,
      dead: game.dead,
      territory: game.pendingScore?.territory ?? const {},
      showCoordinates: settings.showCoordinates,
      onTap: reviewMode ? (_) {} : game.tapPoint,
    );
  }

  Widget _bottomBar(BuildContext ctx) {
    if (reviewMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: WoodButton(
            label: 'Back to results',
            fontSize: 15,
            width: 220,
            onTap: () {
              sound.playTap();
              onReviewDone?.call();
            }),
      );
    }
    if (game.phase == GamePhase.markDead) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(game.scoreLine,
                textAlign: TextAlign.center,
                style: GoTheme.counter(14, color: GoTheme.sumi)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WoodButton(
                    label: 'Undo',
                    primary: false,
                    fontSize: 14,
                    onTap: game.canUndo ? game.undo : null),
                const SizedBox(width: 10),
                WoodButton(
                    label: 'Count the score',
                    fontSize: 15,
                    onTap: game.confirmScore),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WoodDisc(
              icon: Icons.front_hand_outlined,
              label: 'Pass',
              onTap: () => _passOrConfirm(ctx)),
          const SizedBox(width: 18),
          WoodDisc(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onTap: game.canUndo ? game.undo : null),
          const SizedBox(width: 18),
          WoodDisc(
              icon: Icons.flag_outlined,
              label: 'Resign',
              tint: const Color(0xFF8C4A2B),
              onTap: () => _resignDialog(ctx)),
        ],
      ),
    );
  }

  void _passOrConfirm(BuildContext ctx) {
    if (!settings.confirmPass) {
      game.pass();
      return;
    }
    sound.playTap();
    showDialog(
      context: ctx,
      builder: (d) => _WoodDialog(
        title: 'Pass this move?',
        body: game.passes == 1
            ? 'One more pass ends the game and starts scoring.'
            : 'Your turn ends and play passes to the opponent.',
        actions: [
          ('Keep playing', false, () {}),
          ('Pass', true, () => game.pass()),
        ],
      ),
    );
  }

  void _resignDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (d) => _WoodDialog(
        title: 'Resign the game?',
        body: 'Your opponent wins immediately, whatever the board says.',
        actions: [
          ('Keep playing', false, () {}),
          ('Resign', true, () => game.resign()),
        ],
      ),
    );
  }

  void _pauseDialog(BuildContext ctx) {
    game.cancelBot();
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (d) => _WoodDialog(
        title: 'Paused',
        kanji: '休憩',
        body: 'The stones wait patiently.',
        actions: [
          ('Resume', true, () => game.nudgeBot()),
          ('Restart', false, () {
            game.newGame(
              boardSize: game.size,
              gameMode: game.mode,
              botDifficulty: game.difficulty,
              botPlays: game.botColor,
              komiValue: game.komi,
              handicapStones: game.handicap,
            );
          }),
          ('Settings', false, onPauseSettings),
          ('Quit to menu', false, onQuitToMenu),
        ],
      ),
    );
  }
}

/// Animated "thinking…" dots on the active bot's tray.
class _ThinkingDots extends StatefulWidget {
  final int color;
  const _ThinkingDots({required this.color});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final n = (_c.value * 3).floor() + 1;
        return Text('thinking${'.' * n}',
            style: GoTheme.label(11, color: GoTheme.kayaDeep));
      },
    );
  }
}

/// Small wooden dialog used for pause / pass / resign confirmations.
class _WoodDialog extends StatelessWidget {
  final String title;
  final String? kanji;
  final String body;
  final List<(String, bool, VoidCallback)> actions;

  const _WoodDialog(
      {required this.title, this.kanji, required this.body, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: WoodCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoTheme.display(20)),
                if (kanji != null) ...[
                  const SizedBox(width: 8),
                  Text(kanji!, style: GoTheme.body(15, color: GoTheme.inkGrey)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: GoTheme.body(14, color: GoTheme.inkGrey)),
            const SizedBox(height: 18),
            for (final (label, primary, fn) in actions) ...[
              WoodButton(
                label: label,
                primary: primary,
                width: double.infinity,
                onTap: () {
                  Navigator.of(context).pop();
                  fn();
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
