import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The simulation must stay pure Dart and deterministic (PRD: Arsitektur).
void main() {
  final banned = <RegExp, String>{
    RegExp(r"import\s+'package:flutter/"): 'Flutter import',
    RegExp(r"import\s+'package:flame"): 'Flame import',
    RegExp(r"import\s+'dart:ui'"): 'dart:ui import',
    RegExp(r"import\s+'dart:io'"): 'dart:io import',
    // libm results can differ between CPUs; use sim/trig.dart instead.
    // (sqrt is IEEE correctly rounded, so it stays allowed.)
    RegExp(r'\b(sin|cos|tan|asin|acos|atan|atan2|pow|exp|log)\('):
        'platform-dependent math function',
    RegExp(r'\bRandom\('): 'unseeded Random()',
    RegExp(r'\bDateTime\.now\('): 'wall-clock time',
    RegExp(r'\bStopwatch\('): 'wall-clock time',
  };

  final files = Directory('lib/sim')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    test('${file.path} is pure and deterministic', () {
      final src = file.readAsStringSync();
      for (final entry in banned.entries) {
        expect(entry.key.hasMatch(src), isFalse,
            reason: '${entry.value} found in ${file.path}');
      }
    });
  }
}
