import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../services/store_service.dart';
import '../state/settings.dart';
import '../theme.dart';

/// Launch splash, per MASTER_RULES branding:
/// 1. WAJIHA company splash (official logo, untouched).
/// 2. Game splash: Go logo + name + animated loading line + "Credits: WAJIHA".
/// Audio is pre-warmed and menu music starts while the splash shows.
class SplashScreen extends StatefulWidget {
  final SoundService audio;
  final GoSettings settings;
  final StoreService store;
  final VoidCallback onDone;

  const SplashScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.onDone,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loader;
  late final AnimationController _fade;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio + store while the company logo shows.
    widget.audio.prewarm();
    widget.store.init();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _companyDone = true);
    _fade.forward();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _loader.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GoTheme.use(widget.settings.activeTheme);
    BoardLook.use(wood: widget.settings.activeWood, stone: widget.settings.activeStone);
    return Scaffold(
      backgroundColor:
          _companyDone ? GoTheme.tatami : const Color(0xFF0E0B08),
      body: _companyDone
          ? FadeTransition(
              opacity: _fade,
              child: _GameSplash(
                loader: _loader,
                audio: widget.audio,
              ),
            )
          : const _CompanySplash(),
    );
  }
}

/// Company splash: the official WAJIHA logo, untouched.
class _CompanySplash extends StatelessWidget {
  const _CompanySplash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/wajiha_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          const Text(
            'WAJIHA',
            style: TextStyle(
              fontFamily: 'Noto Serif',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final AnimationController loader;
  final SoundService audio;
  const _GameSplash({required this.loader, required this.audio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: GoTheme.kayaDeep, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/go_logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 22),
          Text('Go', style: GoTheme.display(52)),
          const SizedBox(height: 4),
          Text('囲碁', style: GoTheme.body(18, color: GoTheme.inkGrey)),
          const SizedBox(height: 30),
          // Animated loading line.
          SizedBox(
            width: 220,
            child: AnimatedBuilder(
              animation: loader,
              builder: (_, _) => Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: GoTheme.sumi.withValues(alpha: 0.12),
                      border: Border.all(
                          color: GoTheme.kayaDeep.withValues(alpha: 0.5)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: loader.value.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              GoTheme.kayaHoney,
                              GoTheme.kayaDeep,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loader.value < 1 ? 'Setting the stones…' : 'Ready!',
                    style: GoTheme.body(13, color: GoTheme.inkGrey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 44),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/wajiha_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text('Credits: WAJIHA', style: GoTheme.label(14)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The menu is entered through a fade once the splash finishes.
class SplashDone extends StatelessWidget {
  final Widget child;
  const SplashDone({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
