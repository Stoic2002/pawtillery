import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/ui/hud/hud_layout.dart';

void main() {
  test('the HUD layout survives being saved, and rubbish is the default', () {
    final l = HudLayout.standard.withPlacement(
      HudGroup.walk,
      const HudPlacement(offset: Offset(12, -30), scale: 1.3),
    );
    final back = HudLayout.decode(l.encode());
    expect(back.of(HudGroup.walk).offset, const Offset(12, -30));
    expect(back.of(HudGroup.walk).scale, 1.3);
    expect(back.of(HudGroup.actions).scale, 1);
    expect(HudLayout.decode('nonsense').placements, isEmpty);
    expect(HudLayout.decode(null).placements, isEmpty);
  });
}
