import 'package:flutter_test/flutter_test.dart';
import 'package:go/game_screen.dart';

void main() {
  group('GoEngine captures', () {
    test('surrounded single stone is captured', () {
      final b = List<int>.filled(81, 0);
      b[10] = 2; // white at (1,1)
      b[1] = 1;
      b[19] = 1;
      b[9] = 1; // black on 3 sides
      final cap = GoEngine.playOn(b, 9, 11, 1); // black plays (1,2)
      expect(cap, 1);
      expect(b[10], 0);
      expect(b[11], 1);
    });

    test('multi-stone group capture', () {
      final b = List<int>.filled(81, 0);
      b[10] = 2;
      b[11] = 2; // white pair, one liberty left at (1,3)=12
      for (final i in [1, 2, 19, 20, 9]) {
        b[i] = 1; // black walls
      }
      final cap = GoEngine.playOn(b, 9, 12, 1); // black fills the last liberty
      expect(cap, 2);
      expect(b[10], 0);
      expect(b[11], 0);
      expect(b[12], 1);
    });

    test('suicide move is rejected', () {
      final b = List<int>.filled(81, 0);
      b[1] = 2;
      b[9] = 2; // white at (0,1) and (1,0)
      expect(GoEngine.playOn(b, 9, 0, 1), -1); // black at (0,0) = suicide
      expect(b[0], 0); // board untouched
    });

    test('snapback capture is allowed (capture saves the stone)', () {
      final b = List<int>.filled(81, 0);
      // white stone at (1,1) with one liberty at (1,2); black to capture
      b[10] = 2;
      b[1] = 1;
      b[19] = 1;
      b[9] = 1;
      b[20] = 1;
      b[2] = 1; // (0,2)
      // black plays (1,2)=11, capturing white
      expect(GoEngine.playOn(b, 9, 11, 1), 1);
    });
  });

  group('GoEngine ko', () {
    test('immediate recapture repeats the position (ko shape)', () {
      // b0: ko shape, black to capture at (1,2)=11
      final b0 = List<int>.filled(81, 0);
      for (final i in [1, 9, 19]) {
        b0[i] = 1; // black (0,1),(1,0),(2,1)
      }
      for (final i in [2, 20, 12]) {
        b0[i] = 2; // white (0,2),(2,2),(1,3)
      }
      b0[10] = 2; // white stone in atari at (1,1)
      final b1 = List<int>.from(b0);
      expect(GoEngine.playOn(b1, 9, 11, 1), 1); // black captures
      expect(b1[10], 0);
      // white recaptures at (1,1)
      final b2 = List<int>.from(b1);
      expect(GoEngine.playOn(b2, 9, 10, 2), 1);
      // the recapture recreates b0 exactly -> ko
      expect(GoEngine.hash(b2), GoEngine.hash(b0));
    });
  });

  group('GoEngine groups and liberties', () {
    test('connected stones form one group', () {
      final b = List<int>.filled(81, 0);
      b[40] = 1;
      b[41] = 1;
      b[49] = 1;
      final g = GoEngine.group(b, 9, 40);
      expect(g, {40, 41, 49});
    });

    test('liberty count is correct', () {
      final b = List<int>.filled(81, 0);
      b[40] = 1; // (4,4) center: 4 liberties
      expect(GoEngine.libs(b, 9, {40}), 4);
      b[0] = 2; // (0,0) corner: 2 liberties
      expect(GoEngine.libs(b, 9, {0}), 2);
    });

    test('diagonal stones are not connected', () {
      final b = List<int>.filled(81, 0);
      b[40] = 1;
      b[50] = 1; // diagonal
      expect(GoEngine.group(b, 9, 40), {40});
    });
  });

  group('GoEngine misc', () {
    test('star points exist for all sizes', () {
      expect(GoEngine.starPoints(9).length, 5);
      expect(GoEngine.starPoints(13).length, 9);
      expect(GoEngine.starPoints(19).length, 9);
    });

    test('hash distinguishes positions', () {
      final a = List<int>.filled(81, 0);
      final b = List<int>.from(a)..[0] = 1;
      expect(GoEngine.hash(a) == GoEngine.hash(b), false);
    });
  });
}
