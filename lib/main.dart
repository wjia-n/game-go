import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sound.dart';
import 'screens/custom_theme_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/pro_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/store_service.dart';
import 'state/game.dart';
import 'state/settings.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = GoSettings();
  await settings.load();
  final sound = SoundService();
  sound.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    musicVolume: settings.musicVolume,
    sfxVolume: settings.sfxVolume,
  );
  final store = StoreService();
  runApp(GoApp(settings: settings, sound: sound, store: store));
}

enum _Nav { splash, menu, game, gameOver, settings, pro, customTheme }

/// Go — quiet Japanese-minimalist territory game.
/// Navigation is a tiny explicit state machine; screens are pure views over
/// [GoSettings], [GameState], [SoundService] and [StoreService].
class GoApp extends StatefulWidget {
  final GoSettings settings;
  final SoundService sound;
  final StoreService store;
  const GoApp(
      {super.key,
      required this.settings,
      required this.sound,
      required this.store});

  @override
  State<GoApp> createState() => _GoAppState();
}

class _GoAppState extends State<GoApp> with WidgetsBindingObserver {
  late final GameState game;

  _Nav _nav = _Nav.splash;
  _Nav _returnTo = _Nav.menu; // where settings/pro/customTheme return
  bool _reviewing = false;
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    game = GameState(settings: widget.settings, sound: widget.sound);
    game.addListener(_onGameChanged);
    WidgetsBinding.instance.addObserver(this);
    _checkSave();
  }

  Future<void> _checkSave() async {
    _hasSave = await widget.settings.loadSavedGame() != null;
    if (mounted) setState(() {});
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
      widget.sound.startMenuMusic();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) music on interruption so it resumes exactly where it
    // left off; the engine additionally freezes any scheduled bot move.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.sound.onAppPaused();
      game.cancelBot();
    } else if (state == AppLifecycleState.resumed) {
      widget.sound.onAppResumed();
      if (_nav == _Nav.game && !_reviewing) game.nudgeBot();
    }
  }

  // ---- navigation helpers ----

  void _goMenu() async {
    game.cancelBot();
    _hasSave = await widget.settings.loadSavedGame() != null;
    widget.sound.startMenuMusic();
    if (mounted) {
      setState(() {
        _nav = _Nav.menu;
        _reviewing = false;
      });
    }
  }

  void _onPlay() {
    widget.sound.startGameMusic();
    setState(() {
      _nav = _Nav.game;
      _reviewing = false;
    });
  }

  Future<void> _onResume() async {
    final j = await widget.settings.loadSavedGame();
    if (j != null && game.restore(j)) {
      widget.sound.startGameMusic();
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
    widget.sound.startGameMusic();
    setState(() {
      _nav = _Nav.game;
      _reviewing = false;
    });
  }

  void _openOverlay(_Nav which) {
    setState(() {
      _returnTo = _nav;
      _nav = which;
    });
  }

  void _closeOverlay() {
    setState(() => _nav = _returnTo);
    if (_returnTo == _Nav.game && !_reviewing) game.nudgeBot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.removeListener(_onGameChanged);
    game.dispose();
    widget.sound.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        // Apply the active look app-wide whenever settings change.
        final st = widget.settings;
        GoTheme.use(st.activeTheme);
        BoardLook.use(wood: st.activeWood, stone: st.activeStone);
        return MaterialApp(
          title: 'Go',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: GoTheme.tatami,
            colorScheme: ColorScheme.fromSeed(seedColor: GoTheme.kayaDeep),
            useMaterial3: true,
          ),
          home: _screen(),
        );
      },
    );
  }

  Widget _screen() {
    switch (_nav) {
      case _Nav.splash:
        return SplashScreen(
          audio: widget.sound,
          settings: widget.settings,
          store: widget.store,
          onDone: () => setState(() => _nav = _Nav.menu),
        );
      case _Nav.menu:
        return MenuScreen(
          settings: widget.settings,
          sound: widget.sound,
          game: game,
          hasSave: _hasSave,
          onPlay: _onPlay,
          onResume: _onResume,
          onOpenSettings: () => _openOverlay(_Nav.settings),
          onOpenPro: () => _openOverlay(_Nav.pro),
          onOpenCustomTheme: () => _openOverlay(_Nav.customTheme),
        );
      case _Nav.game:
        return GameScreen(
          game: game,
          settings: widget.settings,
          sound: widget.sound,
          reviewMode: _reviewing,
          onReviewDone: () => setState(() {
            _reviewing = false;
            _nav = _Nav.gameOver;
          }),
          onPauseSettings: () => _openOverlay(_Nav.settings),
          onQuitToMenu: _goMenu,
        );
      case _Nav.gameOver:
        return GameOverScreen(
          game: game,
          sound: widget.sound,
          onRematch: _onRematch,
          onReview: () => setState(() {
            _reviewing = true;
            _nav = _Nav.game;
          }),
          onMenu: _goMenu,
        );
      case _Nav.settings:
        return SettingsScreen(
          settings: widget.settings,
          sound: widget.sound,
          onBack: _closeOverlay,
          onOpenPro: () => _openOverlay(_Nav.pro),
        );
      case _Nav.pro:
        return ProScreen(
          audio: widget.sound,
          settings: widget.settings,
          store: widget.store,
          onBack: _closeOverlay,
        );
      case _Nav.customTheme:
        return CustomThemeScreen(
          settings: widget.settings,
          audio: widget.sound,
          onOpenPro: () => _openOverlay(_Nav.pro),
          onBack: _closeOverlay,
        );
    }
  }
}
