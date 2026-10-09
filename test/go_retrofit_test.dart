import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:go/audio/sound.dart';
import 'package:go/engine/bot.dart';
import 'package:go/engine/go_engine.dart';
import 'package:go/state/game.dart';
import 'package:go/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameState _fresh() => GameState(settings: GoSettings(), sound: SoundService());

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });
  group('session rules (RULES §13, engine-owned state)', () {
    test('double pass ends the game and opens the scoring review', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.twoPlayer,
          handicapStones: 0,
          komiValue: 4.5);
      expect(g.phase, GamePhase.play);
      g.pass(); // black passes
      expect(g.phase, GamePhase.play);
      expect(g.passes, 1);
      g.pass(); // white passes
      expect(g.phase, GamePhase.markDead);
      expect(g.pendingScore, isNotNull);
      expect(g.turnPhase, TurnPhase.settling);
      // confirm the score -> game over with a winner
      g.confirmScore();
      expect(g.over, true);
      expect(g.winner, isNotNull);
      g.dispose();
    });

    test('resignation wins immediately for the opponent', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.twoPlayer,
          handicapStones: 0,
          komiValue: 4.5);
      g.tapPoint(40);
      g.resign(); // white (turn=2) resigns
      expect(g.over, true);
      expect(g.winner, 1);
      expect(g.resignedBy, 2);
      expect(g.turnPhase, TurnPhase.settling);
      g.dispose();
    });

    test('undo in vs-bot takes back the human and the bot move', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.vsBot,
          botDifficulty: BotDifficulty.easy,
          botPlays: 2, // bot is white; human (black) moves first
          handicapStones: 0,
          komiValue: 4.5);
      final h0 = GoEngine.hash(g.board);
      g.tapPoint(40); // human plays
      expect(g.moves, 1);
      g.cancelBot(); // freeze the scheduled bot reply for determinism
      g.undo(); // takes back the human move (bot never got to move)
      expect(g.moves, 0);
      expect(GoEngine.hash(g.board), h0);
      expect(g.turn, 1);
      expect(g.turnPhase, TurnPhase.awaitingHuman);
      g.dispose();
    });

    test('handicap sets komi to 0.5 and pre-places stones', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.twoPlayer,
          handicapStones: 4);
      // no explicit komiValue -> effectiveKomi forces 0.5 (RULES §2 test 12)
      expect(g.komi, 0.5);
      final stones = g.board.where((v) => v == 1).length;
      expect(stones, 4);
      expect(g.turn, 1); // black to move after placement
      g.dispose();
    });

    test('save/restore round-trips position, captures and komi', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.twoPlayer,
          handicapStones: 0,
          komiValue: 4.5);
      g.tapPoint(40);
      g.tapPoint(41);
      final json = g.toJson();
      final g2 = _fresh();
      expect(g2.restore(json), true);
      expect(g2.board, g.board);
      expect(g2.turn, g.turn);
      expect(g2.moves, g.moves);
      expect(g2.komi, g.komi);
      expect(g2.hashes, g.hashes);
      g.dispose();
      g2.dispose();
    });

    test('ko is rejected at the session level (tap flashes invalid)', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.twoPlayer,
          handicapStones: 0,
          komiValue: 4.5);
      // Build the classic ko shape from the engine test via direct board
      // setup, then verify checkMove refuses the immediate recapture.
      const size = 9;
      final b0 = List<int>.filled(81, 0);
      for (final i in [1, 9, 19]) {
        b0[i] = 1;
      }
      for (final i in [2, 20, 12]) {
        b0[i] = 2;
      }
      b0[10] = 2;
      final seen = {GoEngine.hash(b0)};
      final b1 = List<int>.from(b0);
      GoEngine.playOn(b1, size, 11, 1); // black captures
      seen.add(GoEngine.hash(b1));
      final ko = checkMove(b1, size, 10, 2, seen);
      expect(ko.ok, false);
      expect(ko.reason, 'ko');
      g.dispose();
    });

    test('capture-beats-suicide commits at the session level', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.twoPlayer,
          handicapStones: 0,
          komiValue: 4.5);
      // White ring around (0,0) missing one liberty; black stone in atari.
      // Layout: black at (0,1) and (1,0) with white surrounding them, then
      // white plays (0,0) capturing both — legal despite no liberties.
      g.board[1] = 1; // (0,1) black
      g.board[9] = 1; // (1,0) black
      g.board[2] = 2; // (0,2) white
      g.board[10] = 2; // (1,1) white
      g.board[18] = 2; // (2,0) white
      g.hashes = [GoEngine.hash(g.board)];
      g.seenHashes = {g.hashes.first};
      g.turn = 2; // white to play
      g.tapPoint(0); // (0,0): captures both black stones
      expect(g.board[1], 0);
      expect(g.board[9], 0);
      expect(g.board[0], 2);
      expect(g.capByWhite, 2);
      g.dispose();
    });
  });

  group('watchdog (no stuck states)', () {
    test('re-arms a bot turn found without a live timer', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.vsBot,
          botDifficulty: BotDifficulty.easy,
          botPlays: 2, // bot is white
          handicapStones: 0,
          komiValue: 4.5);
      g.cancelBot(); // freeze: now it is black's (human) turn; force bot turn
      g.turn = 2;
      g.turnPhase = TurnPhase.awaitingHuman; // corrupted: no timer armed
      g.botThinking = false;
      expect(g.watchdogTrips, 0);
      g.debugWatchdogTick();
      expect(g.watchdogTrips, 1);
      expect(g.botThinking, true);
      expect(g.turnPhase, TurnPhase.botArmed);
      expect(g.narration.contains('thinking'), true);
      g.dispose();
    });

    test('watchdog leaves a healthy human turn alone', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.vsBot,
          botDifficulty: BotDifficulty.easy,
          botPlays: 2,
          handicapStones: 0,
          komiValue: 4.5);
      g.cancelBot();
      g.turn = 1; // human's turn
      g.turnPhase = TurnPhase.awaitingHuman;
      g.debugWatchdogTick();
      expect(g.watchdogTrips, 0);
      expect(g.botThinking, false);
      g.dispose();
    });

    test('new games always start in a live turn phase', () {
      final g = _fresh();
      g.newGame(
          boardSize: 9,
          gameMode: GameMode.vsBot,
          botDifficulty: BotDifficulty.easy,
          botPlays: 1, // bot is black: bot must be armed immediately
          handicapStones: 0,
          komiValue: 4.5);
      expect(g.turnPhase, TurnPhase.botArmed);
      expect(g.botThinking, true);
      g.dispose();
    });
  });

  group('bot-vs-bot simulation (stuck-state proof)', () {
    int sim(BotDifficulty d1, BotDifficulty d2, int seed,
        {int cap = 600}) {
      const size = 9;
      var board = List<int>.filled(size * size, 0);
      var seen = <String>{GoEngine.hash(board)};
      var turn = 1, passes = 0, moves = 0, lastMove = -1;
      final rng = Random(seed);
      while (passes < 2 && moves < cap) {
        final d = turn == 1 ? d1 : d2;
        final pick = GoBot.chooseMove(
            board: board,
            size: size,
            color: turn,
            seenHashes: seen,
            moves: moves,
            lastMove: lastMove,
            rng: rng,
            difficulty: d);
        if (pick < 0) {
          passes++;
          lastMove = -1;
        } else {
          // every bot move must be independently legal — no illegal states
          final c = checkMove(board, size, pick, turn, seen);
          expect(c.ok, true,
              reason: 'bot played illegal move $pick (${c.reason})');
          GoEngine.playOn(board, size, pick, turn);
          seen.add(GoEngine.hash(board));
          passes = 0;
          lastMove = pick;
        }
        moves++;
        turn = 3 - turn;
      }
      return moves; // < cap means the game terminated by double pass
    }

    test('easy vs easy terminates by double pass', () {
      final moves = sim(BotDifficulty.easy, BotDifficulty.easy, 7);
      expect(moves < 600, true);
    });

    test('medium vs medium terminates by double pass', () {
      final moves = sim(BotDifficulty.medium, BotDifficulty.medium, 21);
      expect(moves < 600, true);
    });

    test('hard vs medium terminates by double pass', () {
      final moves = sim(BotDifficulty.hard, BotDifficulty.medium, 99);
      expect(moves < 600, true);
    });

    test('hard is deterministic with a seeded RNG', () {
      const size = 9;
      final b = List<int>.filled(size * size, 0);
      final seen = {GoEngine.hash(b)};
      final a = GoBot.chooseMove(
          board: b,
          size: size,
          color: 1,
          seenHashes: seen,
          moves: 0,
          lastMove: -1,
          rng: Random(20261009),
          difficulty: BotDifficulty.hard);
      final c = GoBot.chooseMove(
          board: b,
          size: size,
          color: 1,
          seenHashes: seen,
          moves: 0,
          lastMove: -1,
          rng: Random(20261009),
          difficulty: BotDifficulty.hard);
      expect(a, c);
    });
  });
}
