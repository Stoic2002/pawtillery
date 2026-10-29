import 'package:flutter_test/flutter_test.dart';
import 'package:pawtillery/config/maps.dart';
import 'package:pawtillery/game/map_loader.dart';
import 'package:pawtillery/sim/rng.dart';
import 'package:pawtillery/sim/spawn.dart';
import 'package:pawtillery/sim/terrain_mask.dart';

void main() {
  late TerrainMask mask;

  testWidgets('sandbox map PNG decodes into a usable mask', (tester) async {
    await tester.runAsync(() async {
      mask = await loadTerrainMask(Maps.sandbox.maskAsset);
    });
    expect((mask.width, mask.height), (2400, 1200));

    // The 3 px thin wall from tool/gen_sandbox_map.py.
    expect(mask.isSolid(1001, 400), isTrue);
    expect(mask.isSolid(1003, 400), isFalse);

    // Room for the largest match: 4 teams × 4 units, for many seeds.
    for (var seed = 0; seed < 5; seed++) {
      final points = findSpawnPoints(
        terrain: mask,
        waterLevel: Maps.sandbox.waterLevel,
        count: 16,
        rng: SimRng(seed),
      );
      expect(points, hasLength(16));
    }
  });

  for (final map in Maps.all) {
    testWidgets('${map.id}: the painting and mask decode, fit 16 units for '
        'many seeds',
        (tester) async {
      late MapData data;
      await tester.runAsync(() async {
        // Throws if the painting isn't a whole multiple of the mask.
        data = await loadMapData(map.maskAsset, artAsset: map.artAsset);
      });
      final mask = data.mask;
      expect((mask.width, mask.height), (3600, 1200));
      // Painted twice as fine as the mask (tool/art/convert_art.py).
      expect(data.artScale, 2);
      expect(data.art, hasLength(7200 * 2400 * 4), reason: 'painted');
      for (var seed = 0; seed < 20; seed++) {
        final points = findSpawnPoints(
          terrain: mask,
          waterLevel: map.waterLevel,
          count: 16,
          rng: SimRng(seed),
        );
        expect(points, hasLength(16), reason: 'seed $seed');
        for (final (_, y) in points) {
          expect(y, lessThan(map.waterLevel));
        }
      }
    });
  }
}
