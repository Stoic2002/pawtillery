import 'package:flutter/material.dart';

import '../../../game/art/sprites.dart';

/// An icon drawn from the painted set (`assets/sprites/ui_<name>.webp`, cut
/// by tool/art/convert_art.py), used like [Icon] and given the same
/// [IconData]. An icon without a painting (and every icon in tests) is the
/// plain [Icon], in [color]; a painting keeps its own colours.
class PawIcon extends StatelessWidget {
  const PawIcon(this.icon, {super.key, this.size, this.color});

  final IconData? icon;
  final double? size;
  final Color? color;

  /// Painting of each icon, and whether it is mirrored.
  static final Map<IconData, (String, {bool flip})> _painted = {
    Icons.play_arrow_rounded: ('play', flip: false),
    Icons.wifi_rounded: ('wifi', flip: false),
    Icons.wifi_tethering_rounded: ('wifi', flip: false),
    Icons.menu_book_rounded: ('book', flip: false),
    Icons.history_rounded: ('history', flip: false),
    Icons.settings_rounded: ('settings', flip: false),
    Icons.info_rounded: ('info', flip: false),
    Icons.pause_rounded: ('pause', flip: false),
    Icons.pause_circle_rounded: ('pause', flip: false),
    Icons.arrow_back_rounded: ('back', flip: false),
    Icons.arrow_forward_rounded: ('back', flip: true),
    Icons.west_rounded: ('back', flip: false),
    Icons.east_rounded: ('back', flip: true),
    Icons.check_rounded: ('check', flip: false),
    Icons.close_rounded: ('close', flip: false),
    Icons.emoji_events_rounded: ('trophy', flip: false),
    Icons.star_rounded: ('star', flip: false),
    Icons.north_east_rounded: ('jump', flip: false),
    Icons.keyboard_double_arrow_up_rounded: ('highJump', flip: false),
    Icons.directions_run_rounded: ('run', flip: false),
    Icons.touch_app_rounded: ('touch', flip: false),
    Icons.center_focus_strong_rounded: ('focus', flip: false),
    Icons.gps_fixed_rounded: ('target', flip: false),
    Icons.water_rounded: ('water', flip: false),
    Icons.ac_unit_rounded: ('snow', flip: false),
    Icons.casino_rounded: ('dice', flip: false),
    Icons.add_rounded: ('plus', flip: false),
    Icons.remove_rounded: ('minus', flip: false),
    Icons.pets_rounded: ('paw', flip: false),
    Icons.music_note_rounded: ('music', flip: false),
    Icons.library_music_rounded: ('music', flip: false),
    Icons.volume_up_rounded: ('volume', flip: false),
    Icons.vibration_rounded: ('vibrate', flip: false),
    Icons.translate_rounded: ('globe', flip: false),
    Icons.speed_rounded: ('speed', flip: false),
    Icons.timeline_rounded: ('aimPath', flip: false),
    Icons.school_rounded: ('school', flip: false),
    Icons.person_rounded: ('person', flip: false),
    Icons.smart_toy_rounded: ('robot', flip: false),
    Icons.shuffle_rounded: ('shuffle', flip: false),
    Icons.delete_rounded: ('trash', flip: false),
    Icons.shield_rounded: ('shield', flip: false),
    Icons.groups_rounded: ('group', flip: false),
    Icons.replay_rounded: ('replay', flip: false),
    Icons.tune_rounded: ('sliders', flip: false),
    Icons.logout_rounded: ('exit', flip: false),
  };

  @override
  Widget build(BuildContext context) {
    final painted = _painted[icon];
    final image = painted == null ? null : Sprites.of('ui_${painted.$1}');
    if (painted == null || image == null) {
      return Icon(icon, size: size, color: color);
    }
    final side = size ?? IconTheme.of(context).size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: Transform.flip(
        flipX: painted.flip,
        child: RawImage(
          image: image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
