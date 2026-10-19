import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Many Android phones drop Wi-Fi broadcast packets to save power unless an
/// app holds a multicast lock, so room beacons would never arrive. Held
/// while the Play on Wi-Fi screens are open (MainActivity.kt); a no-op on
/// other platforms.
abstract final class WifiLock {
  static const _channel = MethodChannel('pawtillery/wifi');

  static Future<void> acquire() => _call('acquireMulticast');

  static Future<void> release() => _call('releaseMulticast');

  static Future<void> _call(String method) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      // Discovery may miss rooms; joining by address still works.
    } on MissingPluginException {
      // Tests.
    }
  }
}
