/// Play on Wi-Fi transport: sockets where `dart:io` exists, a stub on the
/// web (no sockets there; the menu hides the option).
library;

export 'lan_api.dart';
export 'lan_stub.dart' if (dart.library.io) 'lan_io.dart';
