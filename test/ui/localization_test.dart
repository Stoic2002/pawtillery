import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/app/app.dart';

void main() {
  testWidgets('main menu shows English text', (tester) async {
    await tester.pumpWidget(const PawtilleryApp(locale: Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('main menu shows Indonesian text', (tester) async {
    await tester.pumpWidget(const PawtilleryApp(locale: Locale('id')));
    await tester.pumpAndSettle();
    expect(find.text('Main'), findsOneWidget);
  });

  test('non-Indonesian device languages fall back to English', () {
    const supported = [Locale('en'), Locale('id')];
    expect(PawtilleryApp.resolveLocale(const Locale('id', 'ID'), supported),
        const Locale('id'));
    expect(PawtilleryApp.resolveLocale(const Locale('fr'), supported),
        const Locale('en'));
    expect(PawtilleryApp.resolveLocale(null, supported), const Locale('en'));
  });
}
