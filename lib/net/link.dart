import 'dart:async';

import 'protocol.dart';

/// A two-way message channel to one other phone. [messages] ends when the
/// link closes, from either side.
abstract class NetLink {
  /// Single subscription.
  Stream<NetMessage> get messages;

  void send(NetMessage message);

  Future<void> close();
}

/// Two links joined in memory (tests). Every message still goes through
/// the JSON encoder and decoder, like on a real connection.
class MemoryLink implements NetLink {
  MemoryLink._();

  static (MemoryLink, MemoryLink) pair() {
    final a = MemoryLink._();
    final b = MemoryLink._();
    a._other = b;
    b._other = a;
    return (a, b);
  }

  late MemoryLink _other;
  final _in = StreamController<NetMessage>();
  bool _closed = false;

  @override
  Stream<NetMessage> get messages => _in.stream;

  @override
  void send(NetMessage message) {
    if (_closed) return;
    final decoded = decodeMessage(encodeMessage(message));
    if (decoded != null) _other._in.add(decoded);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _other._closed = true;
    await Future.wait([_in.close(), _other._in.close()]);
  }
}
