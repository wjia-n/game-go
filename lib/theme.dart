import 'package:flutter/material.dart';

import 'theme/go_themes.dart';

export 'theme/go_themes.dart';

/// Static theme facade — same API as before, now forwarding to the active
/// [GoThemeDef]. Screens call [GoTheme.use] at the top of build (main.dart
/// also applies it whenever settings change), so every widget re-skins
/// without call-site changes.
///
/// NOTE: token getters are NOT const. Do not use GoTheme colors inside
/// `const` expressions.
abstract final class GoTheme {
  static GoThemeDef _current = GoThemes.classic;

  /// Activate a theme for all subsequent static reads.
  static void use(GoThemeDef t) {
    _current = t;
  }

  static GoThemeDef get current => _current;

  // --- palette (forwarded) --------------------------------------------------
  static Color get tatami => _current.tatami;
  static Color get clamshell => _current.clamshell;
  static Color get kayaHoney => _current.kayaHoney;
  static Color get kayaDeep => _current.kayaDeep;
  static Color get sumi => _current.sumi;
  static Color get inkGrey => _current.inkGrey;
  static Color get slateTop => _current.slateTop;
  static Color get slateDeep => _current.slateDeep;
  static Color get carved => _current.carved;
  static Color get error => _current.error;
  static Color get boardEdge => _current.boardEdge;
  static Color get stoneShadow => _current.stoneShadow;
  static Color get woodShadow => _current.woodShadow;

  // --- typography (forwarded) ------------------------------------------------
  static const serif = 'Noto Serif';
  static const sans = 'Work Sans';

  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w600}) =>
      _current.display(size, weight: weight);

  static TextStyle body(double size,
          {Color? color, FontWeight weight = FontWeight.w400}) =>
      _current.body(size, color: color, weight: weight);

  static TextStyle counter(double size, {Color? color}) =>
      _current.counter(size, color: color);

  static TextStyle label(double size, {Color? color}) =>
      _current.label(size, color: color);

  // --- layout (true consts, not theme-dependent) ------------------------------
  static const radius = Radius.circular(18);
  static const cardRadius = BorderRadius.all(Radius.circular(18));
  static const double touch = 44.0; // minimum touch target
}
