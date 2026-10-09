import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/goban.dart';
import '../widgets/wood.dart';

/// Game board screen: sticky HUD top (nameplates + capture bowls),
/// 1:1 kaya goban, Pass / Undo / Resign discs at the bottom.
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
    return ListenableBuilder(
      listenable: game,
      builder: (ctx, _) => Scaffold(
        backgroundColor: GoTheme.tatami,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(ctx),
              _nameplates(),
              _statusLine(),
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
          boxShadow: const [
            BoxShadow(
                color: GoTheme.woodShadow, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: GoTheme.kayaDeep, size: 22),
      ),
    );
  }

  Widget _nameplates() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(child: _plate(1, game.capByBlack, 'captured')),
          const SizedBox(width: 10),
          Expanded(child: _plate(2, game.capByWhite, 'captured')),
        ],
      ),
    );
  }

  Widget _plate(int color, int captures, String caption) {
    final active = game.turn == color &&
        game.phase == GamePhase.play &&
        !game.over;
    final name = color == 1 ? 'Black' : 'White';
    final who = game.mode == GameMode.vsBot
        ? (color == game.botColor ? 'bot' : 'you')
        : (color == 1 ? 'player 1' : 'player 2');
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
            const BoxShadow(
                color: GoTheme.woodShadow,
                blurRadius: 10,
                offset: Offset(0, 4)),
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
                Text(name,
                    style: GoTheme.body(14, weight: FontWeight.w600)),
                Text(who, style: GoTheme.label(11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$captures', style: GoTheme.counter(17)),
              Text(caption, style: GoTheme.label(10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusLine() {
    String text;
    if (reviewMode) {
      text = game.scoreLine;
    } else if (game.phase == GamePhase.markDead) {
      text = 'tap stone groups to toggle them dead, then count the score';
    } else if (game.botThinking) {
      text = '${game.turn == 1 ? 'Black' : 'White'} is thinking…';
    } else if (game.phase == GamePhase.play) {
      final who = game.mode == GameMode.vsBot && game.turn == game.botColor
          ? 'bot'
          : 'your';
      text =
          'move ${game.moves + 1} · ${game.turn == 1 ? 'black' : 'white'} to play'
          '${game.mode == GameMode.vsBot ? ' ($who move)' : ''}'
          '${game.passes == 1 ? ' · one pass' : ''}';
    } else {
      text = '';
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
                Text(title,
                    style: GoTheme.display(20)),
                if (kanji != null) ...[
                  const SizedBox(width: 8),
                  Text(kanji!,
                      style: GoTheme.body(15,
                          color: GoTheme.inkGrey)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: GoTheme.body(14,
                    color: GoTheme.inkGrey)),
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
