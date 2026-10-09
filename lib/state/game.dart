import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/sound.dart';
import '../engine/bot.dart';
import '../engine/go_engine.dart';
import 'settings.dart';

enum GamePhase { play, markDead, done }

enum GameMode { vsBot, twoPlayer }

class _Snap {
  final List<int> board;
  final int turn, moves, capB, capW, passes, lastMove;
  final List<String> hashes;
  final Set<String> seen;
  final GamePhase phase;
  _Snap(this.board, this.turn, this.moves, this.capB, this.capW, this.passes,
      this.lastMove, this.hashes, this.seen, this.phase);
}

/// Full game session: rules state, bot scheduling, scoring, save/resume.
/// The goban painter and screens only read; all mutation goes through here.
class GameState extends ChangeNotifier {
  final GoSettings settings;
  final SoundService sound;

  GameState({required this.settings, required this.sound});

  // ---- config ----
  int size = 9;
  GameMode mode = GameMode.vsBot;
  BotDifficulty difficulty = BotDifficulty.medium;
  int botColor = 1;
  double komi = 6.5;
  int handicap = 0;

  // ---- live state ----
  List<int> board = [];
  int turn = 1;
  int moves = 0, capByBlack = 0, capByWhite = 0, passes = 0;
  int lastMove = -1;
  int invalidAt = -1; // point flashing red after an illegal tap
  List<String> hashes = [];
  Set<String> seenHashes = {};
  final List<_Snap> _undos = [];
  GamePhase phase = GamePhase.play;
  Set<int> dead = {};
  AreaScore? pendingScore;

  // ---- result ----
  bool over = false;
  int? winner; // 1 black, 2 white, 0 draw
  double? margin;
  int? resignedBy;

  bool botThinking = false;
  int _gen = 0;
  late Random _botRng;

  int get humanColor =>
      mode == GameMode.vsBot ? 3 - botColor : 0; // 0 = both human
  bool get isHumanTurn =>
      mode == GameMode.twoPlayer || turn != botColor || phase != GamePhase.play;
  bool get canUndo =>
      !over && _undos.isNotEmpty && phase != GamePhase.done;

  // ================= setup =================

  void newGame(
      {required int boardSize,
      required GameMode gameMode,
      BotDifficulty? botDifficulty,
      int? botPlays,
      double? komiValue,
      int? handicapStones}) {
    _gen++;
    size = boardSize;
    mode = gameMode;
    difficulty = botDifficulty ?? settings.botDifficulty;
    botColor = botPlays ?? settings.botColor;
    komi = komiValue ?? effectiveKomi(size, handicapStones ?? settings.handicap,
        settings.komi);
    handicap = handicapStones ?? settings.handicap;

    board = List.filled(size * size, 0);
    turn = 1;
    moves = 0;
    capByBlack = 0;
    capByWhite = 0;
    passes = 0;
    lastMove = -1;
    invalidAt = -1;
    hashes = [GoEngine.hash(board)];
    seenHashes = {hashes.first};
    _undos.clear();
    phase = GamePhase.play;
    dead = {};
    pendingScore = null;
    over = false;
    winner = null;
    margin = null;
    resignedBy = null;
    botThinking = false;
    _botRng = difficulty == BotDifficulty.hard ? Random(20261009) : Random();

    // handicap stones (RULES §2, test 12): placed by black, komi 0.5,
    // black to move after placement.
    if (handicap >= 2 && mode == GameMode.twoPlayer) {
      for (final p in GoEngine.handicapPoints(size, handicap)) {
        board[p[0] * size + p[1]] = 1;
      }
      hashes = [GoEngine.hash(board)];
      seenHashes = {hashes.first};
      turn = 1;
    }
    sound.playStart();
    notifyListeners();
    _persist();
    _maybeBot();
  }

  // ================= moves =================

  void _pushUndo() {
    _undos.add(_Snap(
        List<int>.from(board),
        turn,
        moves,
        capByBlack,
        capByWhite,
        passes,
        lastMove,
        List<String>.from(hashes),
        Set<String>.from(seenHashes),
        phase));
    if (_undos.length > 120) _undos.removeAt(0);
  }

  void undo() {
    if (!canUndo) return;
    _gen++;
    botThinking = false;
    if (mode == GameMode.twoPlayer) {
      // one full round = both players' last moves (RULES §12)
      for (var k = 0; k < 2 && _undos.isNotEmpty; k++) {
        _restore(_undos.removeLast());
      }
    } else {
      // vs bot: take back the player's and the bot's last moves
      _restore(_undos.removeLast());
      while (_undos.isNotEmpty && turn == botColor && phase == GamePhase.play) {
        _restore(_undos.removeLast());
      }
    }
    invalidAt = -1;
    sound.playTap();
    notifyListeners();
    _persist();
    _maybeBot();
  }

  void _restore(_Snap s) {
    board = s.board;
    turn = s.turn;
    moves = s.moves;
    capByBlack = s.capB;
    capByWhite = s.capW;
    passes = s.passes;
    lastMove = s.lastMove;
    hashes = s.hashes;
    seenHashes = s.seen;
    phase = s.phase;
    dead = {};
    pendingScore = null;
  }

  /// Tap on intersection [i]. Returns silently; illegal taps flash + thock.
  void tapPoint(int i) {
    if (over) return;
    if (phase == GamePhase.markDead) {
      toggleDead(i);
      return;
    }
    if (phase != GamePhase.play || !isHumanTurn || botThinking) return;
    final check = checkMove(board, size, i, turn, seenHashes);
    if (!check.ok) {
      invalidAt = i;
      sound.playInvalid();
      notifyListeners();
      final g = _gen;
      Future.delayed(const Duration(milliseconds: 450), () {
        if (g == _gen && invalidAt == i) {
          invalidAt = -1;
          notifyListeners();
        }
      });
      return;
    }
    _doMove(i);
  }

  void _doMove(int i) {
    _gen++;
    _pushUndo();
    final b = List<int>.from(board);
    final cap = GoEngine.playOn(b, size, i, turn);
    board = b;
    if (turn == 1) {
      capByBlack += cap;
    } else {
      capByWhite += cap;
    }
    final h = GoEngine.hash(board);
    hashes.add(h);
    seenHashes.add(h);
    moves++;
    passes = 0;
    lastMove = i;
    invalidAt = -1;
    if (cap > 0) {
      sound.playCapture();
    } else {
      sound.playStone(turn == 1);
    }
    _advance();
  }

  void pass() {
    if (over || phase != GamePhase.play || !isHumanTurn || botThinking) return;
    _gen++;
    _pushUndo();
    passes++;
    lastMove = -1;
    sound.playPass();
    if (passes >= 2) {
      // scoring review (RULES §8): auto-guess dead groups, player confirms.
      phase = GamePhase.markDead;
      dead = guessDead(board, size);
      _recount();
      notifyListeners();
      _persist();
      return;
    }
    _advance();
  }

  void _advance() {
    turn = 3 - turn;
    notifyListeners();
    _persist();
    _maybeBot();
  }

  // ================= bot =================

  void _maybeBot() {
    if (over ||
        phase != GamePhase.play ||
        mode != GameMode.vsBot ||
        turn != botColor) {
      return;
    }
    botThinking = true;
    notifyListeners();
    final g = _gen;
    Future.delayed(Duration(milliseconds: 600 + _botRng.nextInt(400)), () {
      if (_gen != g || over || phase != GamePhase.play) return;
      if (mode != GameMode.vsBot || turn != botColor) return;
      botThinking = false;
      final pick = GoBot.chooseMove(
          board: board,
          size: size,
          color: turn,
          seenHashes: seenHashes,
          moves: moves,
          lastMove: lastMove,
          rng: _botRng,
          difficulty: difficulty);
      if (pick < 0) {
        // bot passes (shares the pass path but skips the human guard)
        _gen++;
        _pushUndo();
        passes++;
        lastMove = -1;
        sound.playPass();
        if (passes >= 2) {
          phase = GamePhase.markDead;
          dead = guessDead(board, size);
          _recount();
          notifyListeners();
          _persist();
          return;
        }
        _advance();
      } else {
        _doMove(pick);
      }
    });
  }

  /// Cancels any scheduled bot move (used by pause).
  void cancelBot() {
    _gen++;
    botThinking = false;
    notifyListeners();
  }

  /// Re-arms the bot after a pause (no-op unless it is the bot's turn).
  void nudgeBot() => _maybeBot();

  // ================= scoring =================

  void toggleDead(int i) {
    if (phase != GamePhase.markDead || board[i] == 0) return;
    _gen++;
    final g = GoEngine.group(board, size, i);
    final nd = Set<int>.from(dead);
    if (nd.contains(i)) {
      nd.removeAll(g);
    } else {
      nd.addAll(g);
    }
    dead = nd;
    sound.playTap();
    _recount();
    notifyListeners();
  }

  void _recount() {
    pendingScore = areaScore(board, size, dead, komi);
  }

  String get scoreLine {
    final s = pendingScore;
    if (s == null) return '';
    return 'Black ${s.black.toStringAsFixed(1)}  ·  '
        'White ${s.white.toStringAsFixed(1)}  (komi ${komi.toStringAsFixed(1)})';
  }

  void confirmScore() {
    final s = pendingScore;
    if (s == null || phase != GamePhase.markDead) return;
    _gen++;
    phase = GamePhase.done;
    over = true;
    if ((s.black - s.white).abs() < 1e-9) {
      winner = 0; // jigo — only possible with whole-number komi
      margin = 0;
    } else if (s.black > s.white) {
      winner = 1;
      margin = s.black - s.white;
    } else {
      winner = 2;
      margin = s.white - s.black;
    }
    // captures already reflected in area scoring; bowls stay as displayed
    settings.clearSavedGame();
    final humanWon = mode == GameMode.twoPlayer
        ? true // no single "player" — celebrate the game
        : winner == humanColor;
    if (winner == 0) {
      sound.playTap();
    } else if (humanWon) {
      sound.playWin();
    } else {
      sound.playLose();
    }
    notifyListeners();
  }

  void resign() {
    if (over || phase == GamePhase.done) return;
    _gen++;
    botThinking = false;
    resignedBy = turn;
    winner = 3 - turn;
    margin = null;
    phase = GamePhase.done;
    over = true;
    settings.clearSavedGame();
    final humanLost =
        mode == GameMode.vsBot && winner != humanColor;
    if (humanLost) {
      sound.playLose();
    } else {
      sound.playWin();
    }
    notifyListeners();
  }

  // ================= persistence =================

  Map<String, Object?> toJson() => {
        'size': size,
        'mode': mode.index,
        'difficulty': difficulty.index,
        'botColor': botColor,
        'komi': komi,
        'handicap': handicap,
        'board': board,
        'turn': turn,
        'moves': moves,
        'capB': capByBlack,
        'capW': capByWhite,
        'passes': passes,
        'lastMove': lastMove,
        'hashes': hashes,
        'seen': seenHashes.toList(),
        'phase': phase.index,
      };

  void _persist() {
    if (over) return;
    settings.saveGame(toJson());
  }

  bool restore(Map<String, dynamic> j) {
    try {
      _gen++;
      size = (j['size'] as num).toInt();
      mode = GameMode.values[(j['mode'] as num).toInt()];
      difficulty = BotDifficulty.values[(j['difficulty'] as num).toInt()];
      botColor = (j['botColor'] as num).toInt();
      komi = (j['komi'] as num).toDouble();
      handicap = (j['handicap'] as num).toInt();
      board = (j['board'] as List).map((e) => (e as num).toInt()).toList();
      turn = (j['turn'] as num).toInt();
      moves = (j['moves'] as num).toInt();
      capByBlack = (j['capB'] as num).toInt();
      capByWhite = (j['capW'] as num).toInt();
      passes = (j['passes'] as num).toInt();
      lastMove = (j['lastMove'] as num).toInt();
      hashes = (j['hashes'] as List).map((e) => e as String).toList();
      seenHashes = (j['seen'] as List).map((e) => e as String).toSet();
      phase = GamePhase.values[(j['phase'] as num).toInt()];
      if (phase == GamePhase.done) return false;
      _undos.clear();
      dead = {};
      pendingScore = null;
      over = false;
      winner = null;
      margin = null;
      resignedBy = null;
      botThinking = false;
      invalidAt = -1;
      _botRng = difficulty == BotDifficulty.hard ? Random(20261009) : Random();
      if (phase == GamePhase.markDead) {
        dead = guessDead(board, size);
        _recount();
      }
      notifyListeners();
      _maybeBot();
      return true;
    } catch (_) {
      return false;
    }
  }
}
