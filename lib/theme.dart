import 'package:flutter/material.dart';

/// Stitch "Kishi" design tokens for Go — Japanese minimalism.
/// Tatami room: kaya wood, slate & clamshell stones, soft shoji daylight.
abstract final class GoTheme {
  // --- palette -------------------------------------------------------------
  static const tatami = Color(0xFFF5EFEB); // screen background, washi grain
  static const clamshell = Color(0xFFF9F8F5); // white stones, cards, pill
  static const kayaHoney = Color(0xFFC88A3F); // primary accent, wood highlights
  static const kayaDeep = Color(0xFF865307); // primary actions, carved dividers
  static const sumi = Color(0xFF33302E); // primary text, headlines
  static const inkGrey = Color(0xFF5C554E); // secondary text, placeholders
  static const slateTop = Color(0xFF3A3735); // black stone highlight side
  static const slateDeep = Color(0xFF1A1A1A); // black stone deep side
  static const carved = Color(0xFFEBE1D7); // card perimeters
  static const error = Color(0xFFBA1A1A); // illegal-move flash only
  static const boardEdge = Color(0xFFA5712E); // goban rim

  static const stoneShadow = Color(0x59000000); // rgba(0,0,0,0.35)
  static const woodShadow = Color(0x2E8C531B); // rgba(140,83,27,~0.18)

  // --- typography ------------------------------------------------------------
  // Noto Serif ships on Android; elsewhere Flutter falls back gracefully.
  static const serif = 'Noto Serif';
  static const sans = 'Work Sans';

  static TextStyle display(double size, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(fontFamily: serif, fontSize: size, fontWeight: weight, color: sumi, height: 1.25);

  static TextStyle body(double size, {Color color = sumi, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: serif, fontSize: size, fontWeight: weight, color: color, height: 1.5);

  static TextStyle counter(double size, {Color color = sumi}) => TextStyle(
      fontFamily: sans, fontSize: size, fontWeight: FontWeight.w500, color: color,
      fontFeatures: const [FontFeature.tabularFigures()], height: 1.2);

  static TextStyle label(double size, {Color color = inkGrey}) =>
      TextStyle(fontFamily: sans, fontSize: size, fontWeight: FontWeight.w500, color: color, height: 1.3);

  // --- layout ----------------------------------------------------------------
  static const radius = Radius.circular(18);
  static const cardRadius = BorderRadius.all(Radius.circular(18));
  static const double touch = 44.0; // minimum touch target
}
