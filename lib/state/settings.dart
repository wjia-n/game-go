import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/bot.dart';
import '../engine/go_engine.dart';
import '../theme/go_themes.dart';

/// Persisted user settings + mid-game save. Backed by shared_preferences.
class GoSettings extends ChangeNotifier {
  static const _p = 'go_';

  // --- audio ---
  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.6;
  double sfxVolume = 0.8;

  // --- rules ---
  double komi = 6.5; // per-board default applied at game start
  int handicap = 0; // 0 = none, else 2..9
  bool showCoordinates = false;
  bool confirmPass = true;

  // --- bot ---
  BotDifficulty botDifficulty = BotDifficulty.medium;
  int botColor = 1; // 1 = bot plays black (convention), 2 = white

  // --- player names (every slot renameable, persisted) ---
  String humanName = 'You';
  String botName = 'Kishi';
  String p1Name = 'Player 1';
  String p2Name = 'Player 2';

  // --- look & feel ---
  String themeId = 'kaya';
  String stoneId = 'slate';
  String woodId = 'kaya';
  CustomThemeDef? customTheme;

  // --- pro ---
  bool isPro = false;

  GoThemeDef get activeTheme => GoThemes.byId(themeId, custom: customTheme);
  WoodStyle get activeWood => Woods.byId(woodId);
  StoneStyle get activeStone => StoneStyles.byId(stoneId);

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    musicOn = sp.getBool('${_p}musicOn') ?? true;
    sfxOn = sp.getBool('${_p}sfxOn') ?? true;
    musicVolume = sp.getDouble('${_p}musicVolume') ?? 0.6;
    sfxVolume = sp.getDouble('${_p}sfxVolume') ?? 0.8;
    komi = sp.getDouble('${_p}komi') ?? 6.5;
    handicap = sp.getInt('${_p}handicap') ?? 0;
    showCoordinates = sp.getBool('${_p}showCoordinates') ?? false;
    confirmPass = sp.getBool('${_p}confirmPass') ?? true;
    botDifficulty = BotDifficulty.values[sp.getInt('${_p}botDifficulty') ?? 1];
    botColor = sp.getInt('${_p}botColor') ?? 1;
    humanName = sp.getString('${_p}humanName') ?? 'You';
    botName = sp.getString('${_p}botName') ?? 'Kishi';
    p1Name = sp.getString('${_p}p1Name') ?? 'Player 1';
    p2Name = sp.getString('${_p}p2Name') ?? 'Player 2';
    themeId = sp.getString('${_p}themeId') ?? 'kaya';
    stoneId = sp.getString('${_p}stoneId') ?? 'slate';
    woodId = sp.getString('${_p}woodId') ?? 'kaya';
    customTheme = CustomThemeDef.decode(sp.getString('${_p}customTheme'));
    isPro = sp.getBool('${_p}isPro') ?? false;
    _ensureProEntitlements();
    notifyListeners();
  }

  /// Free tier keeps only free content; Pro unlocks everything.
  /// Never strands the user on a Pro-only selection after expiry/reset.
  void _ensureProEntitlements() {
    if (isPro) return;
    if (botDifficulty == BotDifficulty.hard) {
      botDifficulty = BotDifficulty.medium;
    }
    if (GoThemes.isPro(themeId)) themeId = 'kaya';
    if (StoneStyles.byId(stoneId).isPro) stoneId = 'slate';
    if (Woods.byId(woodId).isPro) woodId = 'kaya';
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('${_p}isPro', v);
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('${_p}musicOn', musicOn);
    await sp.setBool('${_p}sfxOn', sfxOn);
    await sp.setDouble('${_p}musicVolume', musicVolume);
    await sp.setDouble('${_p}sfxVolume', sfxVolume);
    await sp.setDouble('${_p}komi', komi);
    await sp.setInt('${_p}handicap', handicap);
    await sp.setBool('${_p}showCoordinates', showCoordinates);
    await sp.setBool('${_p}confirmPass', confirmPass);
    await sp.setInt('${_p}botDifficulty', botDifficulty.index);
    await sp.setInt('${_p}botColor', botColor);
    await sp.setString('${_p}humanName', humanName);
    await sp.setString('${_p}botName', botName);
    await sp.setString('${_p}p1Name', p1Name);
    await sp.setString('${_p}p2Name', p2Name);
    await sp.setString('${_p}themeId', themeId);
    await sp.setString('${_p}stoneId', stoneId);
    await sp.setString('${_p}woodId', woodId);
    final c = customTheme;
    if (c == null) {
      await sp.remove('${_p}customTheme');
    } else {
      await sp.setString('${_p}customTheme', c.encode());
    }
  }

  void update(void Function() f) {
    f();
    _ensureProEntitlements();
    _save();
    notifyListeners();
  }

  // ---------------- mid-game save / resume ----------------

  /// Serializes a live game so it survives app restarts (RULES test 15).
  Future<void> saveGame(Map<String, Object?> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('${_p}savedGame', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadSavedGame() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('${_p}savedGame');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedGame() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('${_p}savedGame');
  }
}

/// Which komi should a fresh game use? Handicap forces 0.5 (RULES §2);
/// otherwise the user's setting, clamped to 0..10 half-point steps.
double effectiveKomi(int size, int handicap, double setting) {
  if (handicap >= 2) return 0.5;
  final k = (setting * 2).round() / 2.0;
  return k.clamp(0.0, 10.0);
}

/// Default komi choice when the user switches board size on the menu.
double komiForSize(int size) => GoEngine.defaultKomi(size);
