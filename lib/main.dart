import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const GoApp());

class GoApp extends StatelessWidget {
  const GoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.aquaDepth,
      title: 'Go',
      tagline: 'The ancient game of territory — surround, capture, conquer.',
      emoji: '⚫',
      slug: 'go',
      howToPlay: '• Black plays first, then alternate placing stones on intersections\n'
          '• Surround enemy stones to capture them (no liberties = captured)\n'
          '• No suicide moves, and no repeating the previous board (ko)\n'
          '• Pass when you see no good moves — two passes ends the game\n'
          '• Tap groups to mark them dead, then stones + territory decides it (komi 7.5)',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => GoScreen(players: players, callbacks: cb),
    );
  }
}
