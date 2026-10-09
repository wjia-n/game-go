import 'package:flutter/material.dart';

import 'audio/sound.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'state/game.dart';
import 'state/settings.dart';
import 'theme.dart';

void main() => runApp(const GoApp());

enum _Nav { menu, game, gameOver, settings }

/// Go — quiet Japanese-minimalist territory game.
/// Navigation is a tiny explicit state machine; screens are pure views over
/// [GoSettings] and [GameState].
class GoApp extends StatefulWidget {
  const GoApp({super.key});

  @override
  State<GoApp> createState() => _GoAppState();
}

class _GoAppState extends State<GoApp> with WidgetsBindingObserver {
  late final GoSettings settings;
  late final SoundService sound;
  late final GameState game;

  _Nav _nav = _Nav.menu;
  _Nav _settingsReturn = _Nav.menu;
  bool _reviewing = false;
  bool _hasSave = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    settings = GoSettings();
    sound = SoundService();
    game = GameState(settings: settings, sound: sound);
    game.addListener(_onGameChanged);
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    await settings.load();
    await sound.init();
    sound.applySettings(
        sfxOn: settings.sfxOn,
        musicOn: settings.musicOn,
        sfxVolume: settings.sfxVolume,
        musicVolume: settings.musicVolume);
    sound.setMusicMode('menu');
    _hasSave = await settings.loadSavedGame() != null;
    if (mounted) setState(() => _ready = true);
  }

  void _onGameChanged() {
    // the finished game hands off to the results screen exactly once
    if (game.over &&
        game.phase == GamePhase.done &&
        _nav == _Nav.game &&
        !_reviewing &&
        mounted) {
      setState(() {
        _nav = _Nav.gameOver;
        _hasSave = false;
      });
      sound.setMusicMode('menu');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      game.cancelBot();
    } else if (state == AppLifecycleState.resumed) {
      if (_nav == _Nav.game && !_reviewing) game.nudgeBot();
    }
  }

  // ---- navigation helpers ----

  void _goMenu() async {
    game.cancelBot();
    _hasSave = await settings.loadSavedGame() != null;
    sound.setMusicMode('menu');
    if (mounted) {
      setState(() {
        _nav = _Nav.menu;
        _reviewing = false;
      });
    }
  }

  void _onPlay() {
    sound.setMusicMode('game');
    setState(() {
      _nav = _Nav.game;
      _reviewing = false;
    });
  }

  Future<void> _onResume() async {
    final j = await settings.loadSavedGame();
    if (j != null && game.restore(j)) {
      sound.setMusicMode('game');
      setState(() {
        _nav = _Nav.game;
        _reviewing = false;
      });
    } else {
      _goMenu();
    }
  }

  void _onRematch() {
    game.newGame(
      boardSize: game.size,
      gameMode: game.mode,
      botDifficulty: game.difficulty,
      botPlays: game.botColor,
      komiValue: game.komi,
      handicapStones: game.handicap,
    );
    sound.setMusicMode('game');
    setState(() {
      _nav = _Nav.game;
      _reviewing = false;
    });
  }

  void _openSettings(_Nav from) {
    setState(() {
      _settingsReturn = from;
      _nav = _Nav.settings;
    });
  }

  void _closeSettings() {
    setState(() => _nav = _settingsReturn);
    if (_settingsReturn == _Nav.game) game.nudgeBot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.removeListener(_onGameChanged);
    sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: GoTheme.tatami,
        colorScheme: ColorScheme.fromSeed(seedColor: GoTheme.kayaDeep),
        useMaterial3: true,
      ),
      home: !_ready
          ? const Scaffold(
              backgroundColor: GoTheme.tatami,
              body: Center(
                  child: CircularProgressIndicator(
                      color: GoTheme.kayaDeep)),
            )
          : _screen(),
    );
  }

  Widget _screen() {
    switch (_nav) {
      case _Nav.menu:
        return MenuScreen(
          settings: settings,
          sound: sound,
          game: game,
          hasSave: _hasSave,
          onPlay: _onPlay,
          onResume: _onResume,
          onOpenSettings: () => _openSettings(_Nav.menu),
        );
      case _Nav.game:
        return GameScreen(
          game: game,
          settings: settings,
          sound: sound,
          reviewMode: _reviewing,
          onReviewDone: () => setState(() {
            _reviewing = false;
            _nav = _Nav.gameOver;
          }),
          onPauseSettings: () {
            Navigator.of(context).maybePop();
            _openSettings(_Nav.game);
          },
          onQuitToMenu: () {
            Navigator.of(context).maybePop();
            _goMenu();
          },
        );
      case _Nav.gameOver:
        return GameOverScreen(
          game: game,
          sound: sound,
          onRematch: _onRematch,
          onReview: () => setState(() {
            _reviewing = true;
            _nav = _Nav.game;
          }),
          onMenu: _goMenu,
        );
      case _Nav.settings:
        return SettingsScreen(
          settings: settings,
          sound: sound,
          onBack: _closeSettings,
        );
    }
  }
}
