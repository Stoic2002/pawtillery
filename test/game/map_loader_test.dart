import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/config/sandbox.dart';
import 'package:pawtillery/game/map_loader.dart';
import 'package:pawtillery/sim/terrain_mask.dart';

void main() {
  testWidgets('sandbox map PNG decodes into a usable mask', (tester) async {
    late TerrainMask mask;
    await tester.runAsync(() async {
      mask = await loadTerrainMask(Maps.sandbox.maskAsset);
    });
    expect((mask.width, mask.height), (2400, 1200));

    const lx = SandboxConfig.launcherX, ly = SandboxConfig.launcherY;
    expect(mask.isSolid(lx, ly), isFalse, reason: 'launcher must be in air');
    final groundBelow = [
      for (var y = ly; y < ly + 100; y++) mask.isSolid(lx, y)
    ].contains(true);
    expect(groundBelow, isTrue, reason: 'launcher should sit on the plateau');

    // The 3 px thin wall from tool/gen_sandbox_map.py.
    expect(mask.isSolid(1001, 400), isTrue);
    expect(mask.isSolid(1003, 400), isFalse);
  });
}
