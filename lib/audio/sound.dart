import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Go audio — all sounds synthesized in code as WAV bytes, cached once.
/// Identity: wooden stone clicks on kaya, mallet chimes, muted drums,
/// a calm shakuhachi/koto-inspired ambient loop + soft room tone.
///
/// Reliability design (copied from the Ludo exemplar):
/// - Clips are synthesized ONCE and cached; starting music never blocks the
///   UI thread after the first build.
/// - A [_musicGen] generation counter serializes track changes: every
///   start/stop bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins. Music is app-scoped and
///   never silently dies.
/// - SFX uses a small round-robin pool so rapid stone placements never cut
///   each other off; every public method catches player errors — audio can
///   never crash the app.
/// - Lifecycle uses pause()/resume() so an interruption (call, backgrounding)
///   resumes exactly where it left off instead of restarting or dying.
class SoundService {
  static const int _rate = 22050;
  final Random _rand = Random(42);

  final List<AudioPlayer> _sfxPool = [];
  int _poolIdx = 0;
  AudioPlayer? _music;

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.6;
  double sfxVolume = 0.8;

  // Cache synthesized clips so we only build them once.
  final Map<String, Uint8List> _cache = {};

  // Music state machine. [_musicGen] is bumped by every start/stop request;
  // async work checks it still owns the latest generation before touching
  // the player, so overlapping requests can never desync the music.
  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  /// Plain constructor creates no players: safe in unit tests and on
  /// platforms without the audio plugin. Call [prewarm] (the splash does)
  /// before any playback is needed.
  SoundService();

  /// Create the real players. Called once from [prewarm] on a real device.
  /// Failures leave the service in silent no-op mode — audio never crashes.
  Future<void> _ensurePlayers() async {
    if (_playersReady || _disposed) return;
    _playersReady = true; // attempt exactly once
    // runZonedGuarded so a missing plugin (tests, unsupported platforms)
    // can never surface as an unhandled async error from player setup.
    await runZonedGuarded(() async {
      for (var i = 0; i < 3; i++) {
        _sfxPool.add(AudioPlayer());
      }
      _music = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    }, (Object e, StackTrace s) {
      _sfxPool.clear();
      _music = null;
    });
  }

  bool _playersReady = false;

  void configure({
    required bool musicOn,
    required bool sfxOn,
    required double musicVolume,
    required double sfxVolume,
  }) {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    this.musicVolume = musicVolume.clamp(0.0, 1.0);
    this.sfxVolume = sfxVolume.clamp(0.0, 1.0);
    if (!musicOn) {
      stopMusic();
    } else {
      _applyMusicVolume();
      // If music was off and is now on, (re)start the current track.
      final t = _currentTrack;
      if (t != null) {
        _currentTrack = null; // force restart
        if (t == 'menu') {
          startMenuMusic();
        } else {
          startGameMusic();
        }
      }
    }
  }

  void _applyMusicVolume() {
    final m = _music;
    if (m == null) return;
    final v = musicVolume * (_currentTrack == 'menu' ? 0.7 : 0.5);
    try {
      m.setVolume(musicOn ? v : 0.0);
    } catch (_) {}
  }

  /// Pre-build clips off the critical path. Safe to call any time.
  /// Called from the splash screen so gameplay audio is instant.
  Future<void> prewarm() async {
    if (_disposed) return;
    await _ensurePlayers();
    await Future(() {});
    _clickBlackBytes();
    _clickWhiteBytes();
    _menuBytes();
    _gameBytes();
  }

  // ---------------------------------------------------------- WAV synthesis
  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void writeStr(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _noise() => _rand.nextDouble() * 2 - 1;

  Uint8List _clip(String key, List<double> Function() build) =>
      _cache.putIfAbsent(key, () => _wav(build()));

  // ------------------------- clip builders (Go identity) -------------------
  Uint8List _clickBlackBytes() => _clip('click_black', () {
        // Wooden stone click: noise snap + low woody thump.
        final n = (_rate * 0.16).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          final env = exp(-t * 42);
          final thump = sin(2 * pi * 150 * t) * exp(-t * 30) * 0.7;
          final snap = _noise() * exp(-t * 160) * 0.35 * 0.9;
          s[i] = (thump + snap) * env * 1.4;
        }
        return s;
      });

  Uint8List _clickWhiteBytes() => _clip('click_white', () {
        final n = (_rate * 0.16).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          final env = exp(-t * 42);
          final thump = sin(2 * pi * 235 * t) * exp(-t * 30) * 0.7;
          final snap = _noise() * exp(-t * 160) * 0.35 * 1.25;
          s[i] = (thump + snap) * env * 1.4;
        }
        return s;
      });

  Uint8List _invalidBytes() => _clip('invalid', () {
        final n = (_rate * 0.24).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          s[i] = (sin(2 * pi * 105 * t) * exp(-t * 22) * 0.8 +
                  _noise() * exp(-t * 60) * 0.25) *
              1.2;
        }
        return s;
      });

  Uint8List _tapBytes() => _clip('tap', () {
        final n = (_rate * 0.07).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          s[i] = (sin(2 * pi * 520 * t) * exp(-t * 90) * 0.5 +
                  _noise() * exp(-t * 200) * 0.2) *
              1.1;
        }
        return s;
      });

  Uint8List _passBytes() => _clip('pass', () {
        const from = 420.0, to = 240.0, dur = 0.28;
        final n = (_rate * dur).round();
        final s = List<double>.filled(n, 0);
        var phase = 0.0;
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          final f = from + (to - from) * (t / dur);
          phase += 2 * pi * f / _rate;
          s[i] = sin(phase) * sin(pi * t / dur) * 0.5;
        }
        return s;
      });

  Uint8List _captureBytes() => _clip('capture', () {
        final n = (_rate * 0.22).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          final rattle = (t > 0.05 && t < 0.09 ? _noise() * 0.3 : 0.0);
          s[i] =
              (sin(2 * pi * 130 * t) * exp(-t * 26) * 0.7 + rattle * exp(-t * 40)) *
                  1.2;
        }
        return s;
      });

  Uint8List _startBytes() => _clip('start', () {
        const f1 = 329.6, f2 = 440.0;
        final n = (_rate * 0.7).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          final a = sin(2 * pi * f1 * t) * exp(-t * 6) * (t < 0.3 ? 1 : 0.4);
          final b = t > 0.22
              ? sin(2 * pi * f2 * (t - 0.22)) * exp(-(t - 0.22) * 6)
              : 0.0;
          s[i] = (a + b) * 0.45;
        }
        return s;
      });

  Uint8List _winBytes() => _clip('win', () {
        // Mallet chime: pentatonic ascent with warm harmonics.
        const freqs = [659.3, 784.0, 880.0, 987.8, 1174.7, 1318.5];
        final n = (_rate * 2.4).round();
        final s = List<double>.filled(n, 0);
        for (var k = 0; k < freqs.length; k++) {
          final start = (_rate * k * 0.16).round();
          final f = freqs[k];
          for (var i = 0; i + start < n; i++) {
            final t = i / _rate;
            if (t > 1.6) break;
            final env = exp(-t * 3.2) * (1 - exp(-t * 60));
            s[start + i] += (sin(2 * pi * f * t) * 0.6 +
                    sin(2 * pi * f * 2 * t) * 0.18 +
                    sin(2 * pi * f * 2.98 * t) * 0.08) *
                env *
                0.35;
          }
        }
        return s;
      });

  Uint8List _loseBytes() => _clip('lose', () {
        final n = (_rate * 0.7).round();
        final s = List<double>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          s[i] = (sin(2 * pi * 78 * t) * exp(-t * 9) * 0.9 +
                  _noise() * exp(-t * 45) * 0.2) *
              0.9;
        }
        return s;
      });

  Uint8List _menuBytes() => _clip('music_menu', () {
        // 24s calm ambient loop: slow warm pad + sparse koto-like plucks.
        const dur = 24.0;
        final n = (_rate * dur).round();
        final s = List<double>.filled(n, 0);
        const chords = [
          [110.0, 164.8, 220.0, 329.6],
          [87.3, 174.6, 220.0, 349.2],
          [130.8, 196.0, 261.6, 392.0],
          [98.0, 146.8, 246.9, 293.7],
        ];
        const seg = 6.0;
        for (var c = 0; c < 4; c++) {
          for (final f in chords[c]) {
            for (var i = 0; i < _rate * seg; i++) {
              final g = c * seg + i / _rate;
              final idx = (g * _rate).round() % n;
              final t = i / _rate;
              final env = (sin(pi * t / seg) * 0.5 + 0.5);
              s[idx] += (sin(2 * pi * f * t) * 0.5 +
                      sin(2 * pi * f * 2.01 * t) * 0.12) *
                  env *
                  0.028;
            }
          }
        }
        const penta = [587.3, 659.3, 739.9, 880.0, 987.8, 1174.7];
        final pluckRng = Random(7);
        for (var k = 0; k < 14; k++) {
          final start = (pluckRng.nextDouble() * dur * _rate).round();
          final f = penta[pluckRng.nextInt(penta.length)];
          for (var i = 0; i < _rate * 2.2 && start + i < n; i++) {
            final t = i / _rate;
            final env = exp(-t * 2.4) * (1 - exp(-t * 120));
            s[(start + i) % n] +=
                (sin(2 * pi * f * t) * 0.7 + sin(2 * pi * f * 2 * t) * 0.2) *
                    env *
                    0.05;
          }
        }
        final fade = _rate;
        for (var i = 0; i < fade; i++) {
          final a = i / fade;
          final v = s[i] * a + s[n - fade + i] * (1 - a);
          s[i] = v;
          s[n - fade + i] = v;
        }
        return s;
      });

  Uint8List _gameBytes() => _clip('music_game', () {
        // 10s soft room tone: very low brown noise with slow breathing.
        const dur = 10.0;
        final n = (_rate * dur).round();
        final s = List<double>.filled(n, 0);
        var last = 0.0;
        for (var i = 0; i < n; i++) {
          final t = i / _rate;
          last = (last + 0.02 * _noise()) / 1.02;
          final breathe = 0.6 + 0.4 * sin(2 * pi * t / dur);
          s[i] = last * 0.35 * breathe;
        }
        final fade = _rate;
        for (var i = 0; i < fade; i++) {
          final a = i / fade;
          final v = s[i] * a + s[n - fade + i] * (1 - a);
          s[i] = v;
          s[n - fade + i] = v;
        }
        return s;
      });

  // ------------------------------------------------------------------ SFX
  /// Round-robin pool so rapid stone placements never cut each other off.
  /// Every call is guarded: audio can never crash the app.
  Future<void> _play(Uint8List bytes) async {
    if (!sfxOn || _disposed || _sfxPool.isEmpty) return;
    final p = _sfxPool[_poolIdx++ % _sfxPool.length];
    try {
      await p.setVolume(sfxVolume.clamp(0.0, 1.0));
      await p.play(BytesSource(bytes));
    } catch (_) {}
  }

  Future<void> playStone(bool black) =>
      _play(black ? _clickBlackBytes() : _clickWhiteBytes());
  Future<void> playInvalid() => _play(_invalidBytes());
  Future<void> playTap() => _play(_tapBytes());
  Future<void> playPass() => _play(_passBytes());
  Future<void> playCapture() => _play(_captureBytes());
  Future<void> playStart() => _play(_startBytes());
  Future<void> playWin() => _play(_winBytes());
  Future<void> playLose() => _play(_loseBytes());

  // ----------------------------------------------------------------- music
  /// Start (or keep) a music track. Generation-serialized: the latest request
  /// always wins; a start issued while an older one is in flight is never
  /// dropped. Re-requesting the current track just ensures it is audible.
  Future<void> _startTrack(String track, Uint8List Function() bytes) async {
    final m = _music;
    if (_disposed || m == null) return;
    final gen = ++_musicGen;
    if (_currentTrack == track && !_pausedByLifecycle) {
      // Already on this track — make sure it is actually audible.
      try {
        await m.resume();
      } catch (_) {}
      return;
    }
    // Wait for any in-flight op, then bail if superseded meanwhile.
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed || !musicOn) return;
    _musicBusy = true;
    try {
      await m.stop();
      if (gen != _musicGen || _disposed || !musicOn) return;
      _currentTrack = track;
      _pausedByLifecycle = false;
      _applyMusicVolume();
      await m.play(BytesSource(bytes()));
    } catch (_) {
      if (gen == _musicGen) _currentTrack = null;
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> startMenuMusic() => _startTrack('menu', _menuBytes);
  Future<void> startGameMusic() => _startTrack('game', _gameBytes);

  /// App-scoped stop: cancels any pending start, then stops. Used only when
  /// the user turns music OFF — never on screen navigation.
  Future<void> stopMusic() async {
    ++_musicGen; // cancel any in-flight start
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    final m = _music;
    if (_disposed || m == null) return;
    try {
      await m.stop();
    } catch (_) {}
    _currentTrack = null;
    _pausedByLifecycle = false;
  }

  /// App went to background / interruption: pause (not stop) so we resume
  /// exactly where we left off.
  Future<void> onAppPaused() async {
    final m = _music;
    if (_disposed || m == null || _currentTrack == null) return;
    try {
      await m.pause();
      _pausedByLifecycle = true;
    } catch (_) {}
  }

  /// App came back: resume only if we paused it and music is still wanted.
  Future<void> onAppResumed() async {
    final m = _music;
    if (_disposed || m == null || !musicOn || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      await m.resume();
    } catch (_) {
      // Resume failed (e.g. player was released) — restart the track.
      final track = _currentTrack;
      _currentTrack = null;
      if (track == 'menu') {
        await startMenuMusic();
      } else if (track == 'game') {
        await startGameMusic();
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    ++_musicGen;
    try {
      for (final p in _sfxPool) {
        await p.dispose();
      }
      await _music?.dispose();
    } catch (_) {}
    _sfxPool.clear();
    _music = null;
  }
}
