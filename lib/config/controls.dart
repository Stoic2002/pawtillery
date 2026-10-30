/// Touch controls tuning (PRD: Kontrol sentuh Android).
abstract final class ControlsConfig {
  /// The arena HUD is drawn at this share of its designed size.
  static const double hudScale = 0.85;

  /// Share of the predicted path shown by the aim guide.
  static const double aimGuideFraction = 0.25;
  static const int angleStep = 1;
  static const int powerStep = 1;
  static const int initialAngle = 45;
  static const int initialPower = 60;

  /// Slingshot: drag length (logical px) that maps to 100 % power, and the
  /// dead zone around the start point that cancels the aim.
  static const double slingshotMaxDrag = 180;
  static const double slingshotDeadZone = 16;

  /// Camera zoom limits (1 = one world px per logical px).
  static const double minZoom = 0.35;
  static const double maxZoom = 1.0;
  static const double defaultZoom = 0.85;

  /// How far the camera may look past the map edges, world px; above, room
  /// for aircraft clear of the highest ground of a 3600 x 2400 map.
  static const double cameraMarginSide = 200;
  static const double cameraMarginTop = 500;

  /// Camera catch-up rate when following a target, per second.
  static const double cameraFollowRate = 6;
}
