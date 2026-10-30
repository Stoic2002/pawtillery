import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the screen from dimming and sleeping during a match, where the
/// player may watch for a long time without touching it (MainActivity.kt).
/// A no-op on other platforms.
abstract final class ScreenAwake {
  static const _channel = MethodChannel('pawtillery/screen');

  static Future<void> set({required bool on}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } on PlatformException {
      // The screen may sleep; the match itself is unaffected.
    } on MissingPluginException {
      // Tests.
    }
  }
}
