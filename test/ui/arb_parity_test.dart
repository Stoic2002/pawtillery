import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every player-facing string must exist in both EN and ID (PRD: Lokalisasi).
void main() {
  Set<String> keysOf(String path) {
    final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    return json.keys.where((k) => !k.startsWith('@')).toSet();
  }

  test('app_id.arb and app_en.arb have the same keys', () {
    final en = keysOf('lib/l10n/app_en.arb');
    final id = keysOf('lib/l10n/app_id.arb');
    expect(id.difference(en), isEmpty, reason: 'only in ID');
    expect(en.difference(id), isEmpty, reason: 'missing in ID');
  });
}
