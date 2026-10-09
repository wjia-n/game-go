import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/game.dart';
import '../theme.dart';
import '../widgets/goban.dart';
import '../widgets/wood.dart';

/// Game over: final-position board (soft), winner headline + margin,
/// wooden-plaque score breakdown, Rematch / Review / Menu discs.
class GameOverScreen extends StatelessWidget {
  final GameState game;
  final SoundService sound;
  final VoidCallback onRematch;
  final VoidCallback onReview;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.game,
    required this.sound,
    required this.onRematch,
    required this.onReview,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    GoTheme.use(game.settings.activeTheme);
    BoardLook.use(
        wood: game.settings.activeWood, stone: game.settings.activeStone);
    final s = game.pendingScore;
    final w = game.winner;
    final headline = w == 0
        ? 'Draw — jigo'
        : '${game.nameFor(w!)} wins';
    final sub = game.resignedBy != null
        ? '${game.nameFor(3 - game.resignedBy!)} resigned'
        : w == 0
            ? 'an exact tie'
            : 'by ${game.margin!.toStringAsFixed(1)} points';
    final colorLine = w == 0 ? '' : w == 1 ? 'black' : 'white';

    // breakdown: stones on board (dead removed) + territory
    var bStones = 0, wStones = 0, bTerr = 0, wTerr = 0;
    for (var i = 0; i < game.board.length; i++) {
      if (game.dead.contains(i)) continue;
      if (game.board[i] == 1) bStones++;
      if (game.board[i] == 2) wStones++;
    }
    for (final e in (s?.territory ?? const <int, int>{}).entries) {
      if (e.value == 1) {
        bTerr++;
      } else {
        wTerr++;
      }
    }

    return Scaffold(
      backgroundColor: GoTheme.tatami,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Center(
              child: Column(
                children: [
                  Text(headline, style: GoTheme.display(34)),
                  const SizedBox(height: 2),
                  Text('勝',
                      style: GoTheme.body(16,
                          color: GoTheme.inkGrey)),
                  Text(sub,
                      style: GoTheme.body(15,
                          color: GoTheme.inkGrey)),
                  if (colorLine.isNotEmpty)
                    Text('playing $colorLine',
                        style: GoTheme.label(12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Opacity(
                  opacity: 0.96,
                  child: GobanBoard(
                    board: game.board,
                    size: game.size,
                    lastMove: -1,
                    invalidAt: -1,
                    dead: game.dead,
                    territory: s?.territory ?? const {},
                    showCoordinates: false,
                    onTap: (_) {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            WoodCard(
              child: Column(
                children: [
                  const SectionHead(title: 'Score', kanji: '得点'),
                  const SizedBox(height: 10),
                  _row(game.nameFor(1), 'black', bStones, bTerr, 0,
                      (s?.black ?? 0).toStringAsFixed(1), true),
                  Divider(color: GoTheme.carved, height: 18),
                  _row(game.nameFor(2), 'white', wStones, wTerr, game.komi,
                      (s?.white ?? 0).toStringAsFixed(1), false),
                  const SizedBox(height: 6),
                  Text('stones + territory${game.komi > 0 ? ' + komi' : ''} · area scoring',
                      style: GoTheme.label(11)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WoodDisc(
                    icon: Icons.refresh_rounded,
                    label: 'Rematch',
                    onTap: () {
                      sound.playTap();
                      onRematch();
                    }),
                const SizedBox(width: 20),
                WoodDisc(
                    icon: Icons.visibility_outlined,
                    label: 'Review',
                    onTap: () {
                      sound.playTap();
                      onReview();
                    }),
                const SizedBox(width: 20),
                WoodDisc(
                    icon: Icons.home_outlined,
                    label: 'Menu',
                    onTap: () {
                      sound.playTap();
                      onMenu();
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String who, String colorName, int stones, int terr, double komi,
      String total, bool black) {
    return Row(
      children: [
        MiniStone(black: black, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(who,
                  style:
                      GoTheme.body(15, weight: FontWeight.w600)),
              Text(
                  '$colorName · $stones stones · $terr territory'
                  '${komi > 0 ? ' · komi ${komi.toStringAsFixed(1)}' : ''}',
                  style: GoTheme.label(12)),
            ],
          ),
        ),
        Text(total, style: GoTheme.counter(20)),
      ],
    );
  }
}
