import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'game/art/pet_sprites.dart';
import 'game/art/sprites.dart';
import 'ui/widgets/paw/paw_backdrop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Future.wait([
    PetSprites.load(),
    Sprites.load(),
    PawBackdrop.load(),
  ]);
  runApp(const PawtilleryApp());
}
