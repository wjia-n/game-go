import 'dart:convert';

import 'package:flutter/material.dart';

/// Zen theme catalog for Go — Japanese-minimalist art direction.
/// Every theme reuses the same token set (the classic Kishi tokens), so all
/// screens, the goban painter and the wooden widgets re-skin automatically
/// via [GoTheme.use]. No neon, no cyberpunk — calm physical materials only.
///
/// Free: 4 themes. The other 8 are PRO (see ProScreen).
class GoThemeDef {
  final String id;
  final String name;
  final String kanji;
  final bool isPro;

  // --- Kishi token set (same names as the classic theme) ---
  final Color tatami; // screen background
  final Color clamshell; // cards, plates, white-stone cards
  final Color kayaHoney; // primary accent light
  final Color kayaDeep; // primary actions, dividers
  final Color sumi; // primary text
  final Color inkGrey; // secondary text
  final Color slateTop; // dark side light (bowls, accents)
  final Color slateDeep; // dark side deep
  final Color carved; // card perimeters
  final Color error; // illegal-move flash only
  final Color boardEdge; // goban rim
  final Color stoneShadow;
  final Color woodShadow;

  const GoThemeDef({
    required this.id,
    required this.name,
    required this.kanji,
    required this.isPro,
    required this.tatami,
    required this.clamshell,
    required this.kayaHoney,
    required this.kayaDeep,
    required this.sumi,
    required this.inkGrey,
    required this.slateTop,
    required this.slateDeep,
    required this.carved,
    required this.error,
    required this.boardEdge,
    required this.stoneShadow,
    required this.woodShadow,
  });

  TextStyle display(double size, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(
          fontFamily: 'Noto Serif',
          fontSize: size,
          fontWeight: weight,
          color: sumi,
          height: 1.25);

  TextStyle body(double size,
          {Color? color, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
          fontFamily: 'Noto Serif',
          fontSize: size,
          fontWeight: weight,
          color: color ?? sumi,
          height: 1.5);

  TextStyle counter(double size, {Color? color}) => TextStyle(
      fontFamily: 'Work Sans',
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? sumi,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.2);

  TextStyle label(double size, {Color? color}) => TextStyle(
      fontFamily: 'Work Sans',
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? inkGrey,
      height: 1.3);
}

abstract final class GoThemes {
  static const classic = GoThemeDef(
    id: 'kaya',
    name: 'Classic Kaya',
    kanji: '榧',
    isPro: false,
    tatami: Color(0xFFF5EFEB),
    clamshell: Color(0xFFF9F8F5),
    kayaHoney: Color(0xFFC88A3F),
    kayaDeep: Color(0xFF865307),
    sumi: Color(0xFF33302E),
    inkGrey: Color(0xFF5C554E),
    slateTop: Color(0xFF3A3735),
    slateDeep: Color(0xFF1A1A1A),
    carved: Color(0xFFEBE1D7),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFFA5712E),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E8C531B),
  );

  static const tatamiMorning = GoThemeDef(
    id: 'tatami',
    name: 'Tatami Morning',
    kanji: '畳',
    isPro: false,
    tatami: Color(0xFFF8F4E4),
    clamshell: Color(0xFFFFFDF6),
    kayaHoney: Color(0xFFD9A441),
    kayaDeep: Color(0xFF8A6D1F),
    sumi: Color(0xFF3B362C),
    inkGrey: Color(0xFF6E6656),
    slateTop: Color(0xFF44403A),
    slateDeep: Color(0xFF232019),
    carved: Color(0xFFEFE6CF),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFFB08A3C),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E8A6D1F),
  );

  static const bambooGrove = GoThemeDef(
    id: 'bamboo',
    name: 'Bamboo Grove',
    kanji: '竹',
    isPro: false,
    tatami: Color(0xFFF1F3E8),
    clamshell: Color(0xFFFAFBF3),
    kayaHoney: Color(0xFF9AA84E),
    kayaDeep: Color(0xFF5C6E2A),
    sumi: Color(0xFF2E332A),
    inkGrey: Color(0xFF5D6455),
    slateTop: Color(0xFF3B4038),
    slateDeep: Color(0xFF1E211C),
    carved: Color(0xFFE3E7D2),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFF7E8F3E),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E5C6E2A),
  );

  static const inkWash = GoThemeDef(
    id: 'sumi',
    name: 'Ink Wash',
    kanji: '墨',
    isPro: false,
    tatami: Color(0xFFF4F4F2),
    clamshell: Color(0xFFFFFFFF),
    kayaHoney: Color(0xFF8A8A8A),
    kayaDeep: Color(0xFF2B2B2B),
    sumi: Color(0xFF1A1A1A),
    inkGrey: Color(0xFF6B6B6B),
    slateTop: Color(0xFF4A4A4A),
    slateDeep: Color(0xFF0E0E0E),
    carved: Color(0xFFE2E2E2),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFF555555),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E2B2B2B),
  );

  static const cherryDusk = GoThemeDef(
    id: 'cherry',
    name: 'Cherry Dusk',
    kanji: '桜',
    isPro: true,
    tatami: Color(0xFFF9F0EE),
    clamshell: Color(0xFFFFFAF8),
    kayaHoney: Color(0xFFD68A8A),
    kayaDeep: Color(0xFF96555A),
    sumi: Color(0xFF3A2E30),
    inkGrey: Color(0xFF6E5A5D),
    slateTop: Color(0xFF453B3D),
    slateDeep: Color(0xFF241E20),
    carved: Color(0xFFF0DDD9),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFFB07676),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E96555A),
  );

  static const moonlitGarden = GoThemeDef(
    id: 'moon',
    name: 'Moonlit Garden',
    kanji: '月',
    isPro: true,
    tatami: Color(0xFF1E2430),
    clamshell: Color(0xFF2A3242),
    kayaHoney: Color(0xFFC9A86A),
    kayaDeep: Color(0xFFE0BE7E),
    sumi: Color(0xFFF0EAD9),
    inkGrey: Color(0xFF9AA2B2),
    slateTop: Color(0xFF3A4356),
    slateDeep: Color(0xFF12161F),
    carved: Color(0xFF3A4356),
    error: Color(0xFFE08A8A),
    boardEdge: Color(0xFF8A6F42),
    stoneShadow: Color(0x99000000),
    woodShadow: Color(0x40C9A86A),
  );

  static const teaHouse = GoThemeDef(
    id: 'tea',
    name: 'Tea House',
    kanji: '茶',
    isPro: true,
    tatami: Color(0xFFECE5D3),
    clamshell: Color(0xFFF7F1E1),
    kayaHoney: Color(0xFF7A8B4F),
    kayaDeep: Color(0xFF4A5A2E),
    sumi: Color(0xFF2F3128),
    inkGrey: Color(0xFF616355),
    slateTop: Color(0xFF3E4436),
    slateDeep: Color(0xFF20241B),
    carved: Color(0xFFDCD2B8),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFF6E7E42),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E4A5A2E),
  );

  static const autumnMaple = GoThemeDef(
    id: 'maple',
    name: 'Autumn Maple',
    kanji: '楓',
    isPro: true,
    tatami: Color(0xFFF7EEE2),
    clamshell: Color(0xFFFFF8EE),
    kayaHoney: Color(0xFFD07A3A),
    kayaDeep: Color(0xFF96521F),
    sumi: Color(0xFF3A2C22),
    inkGrey: Color(0xFF6E5C4E),
    slateTop: Color(0xFF453A32),
    slateDeep: Color(0xFF251D17),
    carved: Color(0xFFEDDCC6),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFFB26A2E),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E96521F),
  );

  static const mossStone = GoThemeDef(
    id: 'moss',
    name: 'Moss Stone',
    kanji: '苔',
    isPro: true,
    tatami: Color(0xFFEFF0E8),
    clamshell: Color(0xFFF8F9F2),
    kayaHoney: Color(0xFF8B9A7B),
    kayaDeep: Color(0xFF55663F),
    sumi: Color(0xFF2C3129),
    inkGrey: Color(0xFF5F665A),
    slateTop: Color(0xFF3D4239),
    slateDeep: Color(0xFF1F221D),
    carved: Color(0xFFDFE2D2),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFF77875F),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E55663F),
  );

  static const riverside = GoThemeDef(
    id: 'river',
    name: 'Riverside',
    kanji: '川',
    isPro: true,
    tatami: Color(0xFFEEF2F3),
    clamshell: Color(0xFFF8FAFB),
    kayaHoney: Color(0xFF7BA3A8),
    kayaDeep: Color(0xFF45686D),
    sumi: Color(0xFF2A3436),
    inkGrey: Color(0xFF5A686B),
    slateTop: Color(0xFF3A4446),
    slateDeep: Color(0xFF1C2223),
    carved: Color(0xFFDCE4E5),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFF6E9095),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E45686D),
  );

  static const winterHearth = GoThemeDef(
    id: 'hearth',
    name: 'Winter Hearth',
    kanji: '炉',
    isPro: true,
    tatami: Color(0xFF2A2622),
    clamshell: Color(0xFF38322B),
    kayaHoney: Color(0xFFD89A52),
    kayaDeep: Color(0xFFE8AC66),
    sumi: Color(0xFFF5EDE0),
    inkGrey: Color(0xFFB0A48F),
    slateTop: Color(0xFF4A443B),
    slateDeep: Color(0xFF171310),
    carved: Color(0xFF4A443B),
    error: Color(0xFFE08A8A),
    boardEdge: Color(0xFF9A6B35),
    stoneShadow: Color(0x99000000),
    woodShadow: Color(0x40D89A52),
  );

  static const calligrapher = GoThemeDef(
    id: 'parchment',
    name: "Calligrapher's Desk",
    kanji: '書',
    isPro: true,
    tatami: Color(0xFFEFE3C8),
    clamshell: Color(0xFFF9F0DA),
    kayaHoney: Color(0xFFB08A3C),
    kayaDeep: Color(0xFF7A5E22),
    sumi: Color(0xFF33291A),
    inkGrey: Color(0xFF6B5E45),
    slateTop: Color(0xFF413A2E),
    slateDeep: Color(0xFF211C14),
    carved: Color(0xFFE2D2AE),
    error: Color(0xFFBA1A1A),
    boardEdge: Color(0xFF9A7A32),
    stoneShadow: Color(0x59000000),
    woodShadow: Color(0x2E7A5E22),
  );

  static const List<GoThemeDef> all = [
    classic,
    tatamiMorning,
    bambooGrove,
    inkWash,
    cherryDusk,
    moonlitGarden,
    teaHouse,
    autumnMaple,
    mossStone,
    riverside,
    winterHearth,
    calligrapher,
  ];

  static GoThemeDef byId(String id, {CustomThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom.toThemeDef();
    for (final t in all) {
      if (t.id == id) return t;
    }
    return classic;
  }

  static bool isPro(String id) => byId(id).isPro;
}

// ---------------------------------------------------------------------------
/// Board wood styles — the goban's physical material.
/// Free: kaya + bamboo. The rest are PRO.
class WoodStyle {
  final String id;
  final String name;
  final bool isPro;
  final Color light; // gradient top-left
  final Color mid;
  final Color deep; // gradient bottom-right
  final Color grain; // grain line color (with alpha)
  final Color grid; // burned-in grid lines
  final Color rim; // board rim

  const WoodStyle({
    required this.id,
    required this.name,
    required this.isPro,
    required this.light,
    required this.mid,
    required this.deep,
    required this.grain,
    required this.grid,
    required this.rim,
  });
}

abstract final class Woods {
  static const kaya = WoodStyle(
    id: 'kaya',
    name: 'Kaya',
    isPro: false,
    light: Color(0xFFD9A85E),
    mid: Color(0xFFC88A3F),
    deep: Color(0xFFB2762F),
    grain: Color(0x1A8A5410),
    grid: Color(0xD94A2F0E),
    rim: Color(0xD9A5712E),
  );
  static const bamboo = WoodStyle(
    id: 'bamboo',
    name: 'Bamboo',
    isPro: false,
    light: Color(0xFFE3C878),
    mid: Color(0xFFD4B25C),
    deep: Color(0xFFB8943F),
    grain: Color(0x228A6A10),
    grid: Color(0xD95A4010),
    rim: Color(0xD9B8943F),
  );
  static const shinKaya = WoodStyle(
    id: 'shinkaya',
    name: 'Shin-Kaya',
    isPro: true,
    light: Color(0xFFE0B96E),
    mid: Color(0xFFD09A4A),
    deep: Color(0xFFB57E32),
    grain: Color(0x148A5410),
    grid: Color(0xD94A2F0E),
    rim: Color(0xD9B57E32),
  );
  static const agathis = WoodStyle(
    id: 'agathis',
    name: 'Agathis',
    isPro: true,
    light: Color(0xFFE8D6A8),
    mid: Color(0xFFDCC48C),
    deep: Color(0xFFC4A86E),
    grain: Color(0x1A7A5E20),
    grid: Color(0xD95A4010),
    rim: Color(0xD9C4A86E),
  );
  static const oak = WoodStyle(
    id: 'oak',
    name: 'Oak',
    isPro: true,
    light: Color(0xFFD9B98A),
    mid: Color(0xFFC49E66),
    deep: Color(0xFFA67E48),
    grain: Color(0x2E6E4E10),
    grid: Color(0xD94A2E0E),
    rim: Color(0xD9A67E48),
  );
  static const walnut = WoodStyle(
    id: 'walnut',
    name: 'Walnut',
    isPro: true,
    light: Color(0xFF8A6242),
    mid: Color(0xFF6E4A2E),
    deep: Color(0xFF54341E),
    grain: Color(0x2E2E1A08),
    grid: Color(0xE8E8D6BE),
    rim: Color(0xD954341E),
  );
  static const cherry = WoodStyle(
    id: 'cherry',
    name: 'Cherry',
    isPro: true,
    light: Color(0xFFD89A68),
    mid: Color(0xFFC07E4C),
    deep: Color(0xFF9E5E32),
    grain: Color(0x2E7A3E10),
    grid: Color(0xD94A2410),
    rim: Color(0xD99E5E32),
  );
  static const ebony = WoodStyle(
    id: 'ebony',
    name: 'Ebony',
    isPro: true,
    light: Color(0xFF4A423C),
    mid: Color(0xFF332E2A),
    deep: Color(0xFF211D1A),
    grain: Color(0x2E0E0A08),
    grid: Color(0xE8E8D6BE),
    rim: Color(0xD9211D1A),
  );

  static const List<WoodStyle> all = [
    kaya,
    bamboo,
    shinKaya,
    agathis,
    oak,
    walnut,
    cherry,
    ebony,
  ];

  static WoodStyle byId(String id) {
    for (final w in all) {
      if (w.id == id) return w;
    }
    return kaya;
  }
}

// ---------------------------------------------------------------------------
/// Stone styles — the physical material of the stones.
/// Free: slate, onyx, pebble, paper. The rest are PRO.
class StoneStyle {
  final String id;
  final String name;
  final bool isPro;
  final Color blackTop;
  final Color blackDeep;
  final Color blackGlint;
  final Color whiteTop;
  final Color whiteMid;
  final Color whiteDeep;
  final Color whiteBand;
  final Color whiteRim;

  const StoneStyle({
    required this.id,
    required this.name,
    required this.isPro,
    required this.blackTop,
    required this.blackDeep,
    required this.blackGlint,
    required this.whiteTop,
    required this.whiteMid,
    required this.whiteDeep,
    required this.whiteBand,
    required this.whiteRim,
  });
}

abstract final class StoneStyles {
  static const slate = StoneStyle(
    id: 'slate',
    name: 'Slate & Clamshell',
    isPro: false,
    blackTop: Color(0xFF3A3735),
    blackDeep: Color(0xFF1A1A1A),
    blackGlint: Color(0x29FFFFFF),
    whiteTop: Color(0xFFFFFFFF),
    whiteMid: Color(0xFFEDE6D4),
    whiteDeep: Color(0xFFDCD2BC),
    whiteBand: Color(0x24B8A888),
    whiteRim: Color(0x38F0C87E),
  );
  static const onyx = StoneStyle(
    id: 'onyx',
    name: 'Polished Onyx',
    isPro: false,
    blackTop: Color(0xFF2E2A33),
    blackDeep: Color(0xFF0D0B10),
    blackGlint: Color(0x3DFFFFFF),
    whiteTop: Color(0xFFFFFFFF),
    whiteMid: Color(0xFFEFE9DC),
    whiteDeep: Color(0xFFD8CFBB),
    whiteBand: Color(0x20B0A890),
    whiteRim: Color(0x30E8D0A0),
  );
  static const pebble = StoneStyle(
    id: 'pebble',
    name: 'River Pebble',
    isPro: false,
    blackTop: Color(0xFF5A5A58),
    blackDeep: Color(0xFF2E2E2C),
    blackGlint: Color(0x1FFFFFFF),
    whiteTop: Color(0xFFF4F1E8),
    whiteMid: Color(0xFFE2DCCB),
    whiteDeep: Color(0xFFCBC3AE),
    whiteBand: Color(0x2EA8A090),
    whiteRim: Color(0x28C8B88E),
  );
  static const paper = StoneStyle(
    id: 'paper',
    name: 'Charcoal & Paper',
    isPro: false,
    blackTop: Color(0xFF444444),
    blackDeep: Color(0xFF161616),
    blackGlint: Color(0x14FFFFFF),
    whiteTop: Color(0xFFFBF9F4),
    whiteMid: Color(0xFFF0EBDD),
    whiteDeep: Color(0xFFE0D7C2),
    whiteBand: Color(0x1AC0B498),
    whiteRim: Color(0x20D8BC7E),
  );
  static const jade = StoneStyle(
    id: 'jade',
    name: 'Jade & Ivory',
    isPro: true,
    blackTop: Color(0xFF2E4A42),
    blackDeep: Color(0xFF122420),
    blackGlint: Color(0x33FFFFFF),
    whiteTop: Color(0xFFFFFFF8),
    whiteMid: Color(0xFFF2EAD2),
    whiteDeep: Color(0xFFDCCFAE),
    whiteBand: Color(0x28A89878),
    whiteRim: Color(0x40B8D8A0),
  );
  static const agate = StoneStyle(
    id: 'agate',
    name: 'Smoked Agate',
    isPro: true,
    blackTop: Color(0xFF4E4442),
    blackDeep: Color(0xFF241E1C),
    blackGlint: Color(0x2BFFFFFF),
    whiteTop: Color(0xFFF8F4EC),
    whiteMid: Color(0xFFE8DDD0),
    whiteDeep: Color(0xFFD0C0AC),
    whiteBand: Color(0x30A08088),
    whiteRim: Color(0x38E0B890),
  );
  static const rosewood = StoneStyle(
    id: 'rosewood',
    name: 'Rosewood & Bone',
    isPro: true,
    blackTop: Color(0xFF4A3030),
    blackDeep: Color(0xFF1E1212),
    blackGlint: Color(0x2BFFFFFF),
    whiteTop: Color(0xFFF6F1E4),
    whiteMid: Color(0xFFEAE0CC),
    whiteDeep: Color(0xFFD4C4A6),
    whiteBand: Color(0x28A89078),
    whiteRim: Color(0x38D8A878),
  );
  static const lacquer = StoneStyle(
    id: 'lacquer',
    name: 'Midnight Lacquer',
    isPro: true,
    blackTop: Color(0xFF1E1E26),
    blackDeep: Color(0xFF060608),
    blackGlint: Color(0x47FFFFFF),
    whiteTop: Color(0xFFFFFFFF),
    whiteMid: Color(0xFFECE8DE),
    whiteDeep: Color(0xFFD5CDB8),
    whiteBand: Color(0x20A8A8B8),
    whiteRim: Color(0x30F0D8A8),
  );

  static const List<StoneStyle> all = [
    slate,
    onyx,
    pebble,
    paper,
    jade,
    agate,
    rosewood,
    lacquer,
  ];

  static StoneStyle byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return slate;
  }
}

// ---------------------------------------------------------------------------
/// User-built custom theme (PRO). Stored as JSON in settings.
class CustomThemeDef {
  final Color tatami;
  final Color clamshell;
  final Color accent;
  final Color accentDeep;
  final Color text;
  final bool dark;

  const CustomThemeDef({
    required this.tatami,
    required this.clamshell,
    required this.accent,
    required this.accentDeep,
    required this.text,
    required this.dark,
  });

  GoThemeDef toThemeDef() => GoThemeDef(
        id: 'custom',
        name: 'My Theme',
        kanji: '自',
        isPro: true,
        tatami: tatami,
        clamshell: clamshell,
        kayaHoney: accent,
        kayaDeep: accentDeep,
        sumi: text,
        inkGrey: dark
            ? const Color(0xFFB0A89A)
            : Color(text.toARGB32()).withValues(alpha: 0.62),
        slateTop: dark ? const Color(0xFF4A443B) : const Color(0xFF3A3735),
        slateDeep: dark ? const Color(0xFF171310) : const Color(0xFF1A1A1A),
        carved: dark ? const Color(0xFF4A443B) : const Color(0xFFEBE1D7),
        error: const Color(0xFFBA1A1A),
        boardEdge: accentDeep,
        stoneShadow: const Color(0x59000000),
        woodShadow: Color(accentDeep.toARGB32()).withValues(alpha: 0.18),
      );

  Map<String, Object?> toJson() => {
        'tatami': tatami.toARGB32(),
        'clamshell': clamshell.toARGB32(),
        'accent': accent.toARGB32(),
        'accentDeep': accentDeep.toARGB32(),
        'text': text.toARGB32(),
        'dark': dark,
      };

  static CustomThemeDef? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    try {
      return CustomThemeDef(
        tatami: Color((j['tatami'] as num).toInt()),
        clamshell: Color((j['clamshell'] as num).toInt()),
        accent: Color((j['accent'] as num).toInt()),
        accentDeep: Color((j['accentDeep'] as num).toInt()),
        text: Color((j['text'] as num).toInt()),
        dark: j['dark'] as bool,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  static CustomThemeDef? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
/// App-wide board material holder. Screens call [BoardLook.use] whenever
/// settings change; the goban painter reads the current styles.
abstract final class BoardLook {
  static WoodStyle _wood = Woods.kaya;
  static StoneStyle _stone = StoneStyles.slate;

  static void use({WoodStyle? wood, StoneStyle? stone}) {
    if (wood != null) _wood = wood;
    if (stone != null) _stone = stone;
  }

  static WoodStyle get wood => _wood;
  static StoneStyle get stone => _stone;
}
