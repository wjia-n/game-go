import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// All audio is synthesized programmatically — no downloaded assets.
/// Identity: wooden stone clicks on kaya, mallet chimes, muted drums,
/// a calm shakuhachi/koto-inspired ambient loop.
class SoundService {
  static const _sr = 22050;
  final _rnd = Random(42);

  final _sfxPool = <AudioPlayer>[];
  int _poolIdx = 0;
  final _music = AudioPlayer();
  String _mode = 'none';

  bool sfxOn = true;
  bool musicOn = true;
  double sfxVolume = 0.8;
  double musicVolume = 0.6;

  Uint8List? _clickBlack, _clickWhite, _invalid, _tap, _pass, _capture,
      _start, _win, _lose;
  Uint8List? _menuMusic, _roomTone;
  bool _buildingMusic = false;

  Future<void> init() async {
    for (var i = 0; i < 4; i++) {
      _sfxPool.add(AudioPlayer());
    }
    await _music.setReleaseMode(ReleaseMode.loop);
    _clickBlack = _stoneClick(150, 0.9);
    _clickWhite = _stoneClick(235, 1.25);
    _invalid = _thock(105, 0.24);
    _tap = _woodTap();
    _pass = _sweep(420, 240, 0.28);
    _capture = _captureKnock();
    _start = _twoTone(329.6, 440.0);
    _win = _chime();
    _lose = _mutedDrum();
  }

  // ---------------- public API ----------------

  void playStone(bool black) => _play(black ? _clickBlack : _clickWhite);
  void playInvalid() => _play(_invalid);
  void playTap() => _play(_tap);
  void playPass() => _play(_pass);
  void playCapture() => _play(_capture);
  void playStart() => _play(_start);
  void playWin() => _play(_win);
  void playLose() => _play(_lose);

  void _play(Uint8List? bytes) {
    if (!sfxOn || bytes == null || _sfxPool.isEmpty) return;
    final p = _sfxPool[_poolIdx++ % _sfxPool.length];
    p.setVolume(sfxVolume.clamp(0.0, 1.0));
    p.play(BytesSource(bytes));
  }

  /// mode: 'menu' | 'game' | 'none'
  void setMusicMode(String mode) {
    if (mode == _mode) return;
    _mode = mode;
    if (!musicOn || mode == 'none') {
      _music.stop();
      return;
    }
    if (mode == 'menu') {
      _ensureMusic().then((_) {
        if (_mode == 'menu' && musicOn && _menuMusic != null) {
          _music.setVolume(musicVolume * 0.7);
          _music.play(BytesSource(_menuMusic!));
        }
      });
    } else if (mode == 'game') {
      _ensureMusic().then((_) {
        if (_mode == 'game' && musicOn && _roomTone != null) {
          _music.setVolume(musicVolume * 0.5);
          _music.play(BytesSource(_roomTone!));
        }
      });
    }
  }

  void applySettings(
      {required bool sfxOn,
      required bool musicOn,
      required double sfxVolume,
      required double musicVolume}) {
    this.sfxOn = sfxOn;
    this.sfxVolume = sfxVolume;
    final wasMusic = this.musicOn;
    this.musicOn = musicOn;
    this.musicVolume = musicVolume;
    if (!musicOn) {
      _music.stop();
    } else if (!wasMusic) {
      final m = _mode;
      _mode = 'none'; // force restart
      setMusicMode(m);
    } else {
      _music.setVolume(musicVolume * (_mode == 'menu' ? 0.7 : 0.5));
    }
  }

  Future<void> _ensureMusic() async {
    if (_menuMusic != null && _roomTone != null) return;
    if (_buildingMusic) return;
    _buildingMusic = true;
    // generate off the hot path; callers attach via .then
    await Future(() {
      _menuMusic = _ambientLoop();
      _roomTone = _roomToneLoop();
    });
    _buildingMusic = false;
  }

  Future<void> dispose() async {
    for (final p in _sfxPool) {
      await p.dispose();
    }
    await _music.dispose();
  }

  // ---------------- synthesis ----------------

  Uint8List _wav(List<double> s) {
    final n = s.length;
    final data = ByteData(44 + n * 2);
    void str(int o, String v) {
      for (var i = 0; i < v.length; i++) {
        data.setUint8(o + i, v.codeUnitAt(i));
      }
    }
    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _sr, Endian.little);
    data.setUint32(28, _sr * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = s[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _noise() => _rnd.nextDouble() * 2 - 1;

  /// Wooden stone click: noise snap + low woody thump. Higher freq = white.
  Uint8List _stoneClick(double freq, double brightness) {
    final n = (_sr * 0.16).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = exp(-t * 42);
      final thump = sin(2 * pi * freq * t) * exp(-t * 30) * 0.7;
      final snap = _noise() * exp(-t * 160) * 0.35 * brightness;
      s[i] = (thump + snap) * env * 1.4;
    }
    return _wav(s);
  }

  Uint8List _thock(double freq, double dur) {
    final n = (_sr * dur).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      s[i] = (sin(2 * pi * freq * t) * exp(-t * 22) * 0.8 +
              _noise() * exp(-t * 60) * 0.25) *
          1.2;
    }
    return _wav(s);
  }

  Uint8List _woodTap() {
    final n = (_sr * 0.07).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      s[i] = (sin(2 * pi * 520 * t) * exp(-t * 90) * 0.5 +
              _noise() * exp(-t * 200) * 0.2) *
          1.1;
    }
    return _wav(s);
  }

  Uint8List _sweep(double from, double to, double dur) {
    final n = (_sr * dur).round();
    final s = List<double>.filled(n, 0);
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final f = from + (to - from) * (t / dur);
      phase += 2 * pi * f / _sr;
      s[i] = sin(phase) * sin(pi * t / dur) * 0.5;
    }
    return _wav(s);
  }

  Uint8List _captureKnock() {
    final n = (_sr * 0.22).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final rattle = (t > 0.05 && t < 0.09 ? _noise() * 0.3 : 0.0);
      s[i] = (sin(2 * pi * 130 * t) * exp(-t * 26) * 0.7 + rattle * exp(-t * 40)) * 1.2;
    }
    return _wav(s);
  }

  Uint8List _twoTone(double f1, double f2) {
    final n = (_sr * 0.7).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final a = sin(2 * pi * f1 * t) * exp(-t * 6) * (t < 0.3 ? 1 : 0.4);
      final b = t > 0.22 ? sin(2 * pi * f2 * (t - 0.22)) * exp(-(t - 0.22) * 6) : 0.0;
      s[i] = (a + b) * 0.45;
    }
    return _wav(s);
  }

  /// Mallet chime: pentatonic ascent with warm harmonics.
  Uint8List _chime() {
    const freqs = [659.3, 784.0, 880.0, 987.8, 1174.7, 1318.5];
    final n = (_sr * 2.4).round();
    final s = List<double>.filled(n, 0);
    for (var k = 0; k < freqs.length; k++) {
      final start = (_sr * k * 0.16).round();
      final f = freqs[k];
      for (var i = 0; i + start < n; i++) {
        final t = i / _sr;
        if (t > 1.6) break;
        final env = exp(-t * 3.2) * (1 - exp(-t * 60));
        s[start + i] += (sin(2 * pi * f * t) * 0.6 +
                sin(2 * pi * f * 2 * t) * 0.18 +
                sin(2 * pi * f * 2.98 * t) * 0.08) *
            env *
            0.35;
      }
    }
    return _wav(s);
  }

  Uint8List _mutedDrum() {
    final n = (_sr * 0.7).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      s[i] = (sin(2 * pi * 78 * t) * exp(-t * 9) * 0.9 +
              _noise() * exp(-t * 45) * 0.2) *
          0.9;
    }
    return _wav(s);
  }

  /// 24s calm ambient loop: slow warm pad + sparse koto-like plucks.
  Uint8List _ambientLoop() {
    const dur = 24.0;
    final n = (_sr * dur).round();
    final s = List<double>.filled(n, 0);
    // chord roots: A2, F2, C3, G2 with soft major-ish voicings
    const chords = [
      [110.0, 164.8, 220.0, 329.6], // Am add9-ish
      [87.3, 174.6, 220.0, 349.2], // F
      [130.8, 196.0, 261.6, 392.0], // C
      [98.0, 146.8, 246.9, 293.7], // G
    ];
    const seg = 6.0;
    for (var c = 0; c < 4; c++) {
      for (final f in chords[c]) {
        for (var i = 0; i < _sr * seg; i++) {
          final g = c * seg + i / _sr;
          final idx = (g * _sr).round() % n;
          final t = i / _sr;
          final env = (sin(pi * t / seg) * 0.5 + 0.5); // slow swell
          s[idx] += (sin(2 * pi * f * t) * 0.5 +
                  sin(2 * pi * f * 2.01 * t) * 0.12) *
              env *
              0.028;
        }
      }
    }
    // sparse pentatonic plucks (D major pentatonic, koto-like decay)
    const penta = [587.3, 659.3, 739.9, 880.0, 987.8, 1174.7];
    final pluckRng = Random(7);
    for (var k = 0; k < 14; k++) {
      final start = (pluckRng.nextDouble() * dur * _sr).round();
      final f = penta[pluckRng.nextInt(penta.length)];
      for (var i = 0; i < _sr * 2.2 && start + i < n; i++) {
        final t = i / _sr;
        final env = exp(-t * 2.4) * (1 - exp(-t * 120));
        s[(start + i) % n] +=
            (sin(2 * pi * f * t) * 0.7 + sin(2 * pi * f * 2 * t) * 0.2) *
                env *
                0.05;
      }
    }
    // gentle loop crossfade on the last/first second
    final fade = _sr;
    for (var i = 0; i < fade; i++) {
      final a = i / fade;
      final v = s[i] * a + s[n - fade + i] * (1 - a);
      s[i] = v;
      s[n - fade + i] = v;
    }
    return _wav(s);
  }

  /// 10s soft room tone: very low brown noise with slow breathing.
  Uint8List _roomToneLoop() {
    const dur = 10.0;
    final n = (_sr * dur).round();
    final s = List<double>.filled(n, 0);
    var last = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      last = (last + 0.02 * _noise()) / 1.02;
      final breathe = 0.6 + 0.4 * sin(2 * pi * t / dur);
      s[i] = last * 0.35 * breathe;
    }
    final fade = _sr;
    for (var i = 0; i < fade; i++) {
      final a = i / fade;
      final v = s[i] * a + s[n - fade + i] * (1 - a);
      s[i] = v;
      s[n - fade + i] = v;
    }
    return _wav(s);
  }
}
