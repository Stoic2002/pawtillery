/// Seeded PRNG (mulberry32). The only source of randomness allowed in the
/// simulation. Pure 32-bit integer math so the sequence is identical on every
/// device for the same seed.
class SimRng {
  SimRng(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;

  int _state;

  /// Current internal state; restore it with [state] setter for snapshots.
  int get state => _state;
  set state(int value) => _state = value & _mask;

  /// Uniform unsigned 32-bit integer.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & _mask;
    return (t ^ (t >>> 14)) & _mask;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Uniform integer in [min, max] (inclusive).
  int nextIntInRange(int min, int max) {
    assert(max >= min);
    return min + nextUint32() % (max - min + 1);
  }

  static int _imul(int a, int b) => (a * b) & _mask;
}
