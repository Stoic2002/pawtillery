import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../config/controls.dart';
import '../../l10n/app_localizations.dart';
import '../hud/hud_layout.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_widgets.dart';

/// Settings → Arrange HUD: stand-ins for the match HUD's parts, laid out and
/// scaled as in a match. Drag one to move it, pick one to size it. The layout
/// is kept here while it changes and saved when a gesture ends.
class HudLayoutScreen extends StatefulWidget {
  const HudLayoutScreen({super.key});

  @override
  State<HudLayoutScreen> createState() => _HudLayoutScreenState();
}

class _HudLayoutScreenState extends State<HudLayoutScreen> {
  late HudLayout _layout = AppServices.of(context).settings.hudLayout;
  HudGroup _chosen = HudGroup.actions;
  final Map<HudGroup, GlobalKey> _keys = {
    for (final g in HudGroup.values) g: GlobalKey(),
  };

  void _save() => AppServices.of(context).settings.hudLayout = _layout;

  void _drag(HudGroup g, Offset screenDelta, Size screen) {
    final box = _keys[g]!.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
    final moved = Offset(
      screenDelta.dx.clamp(
        -topLeft.dx,
        (screen.width - bottomRight.dx).clamp(0, double.infinity),
      ),
      screenDelta.dy.clamp(
        -topLeft.dy,
        (screen.height - bottomRight.dy).clamp(0, double.infinity),
      ),
    );
    final p = _layout.of(g);
    setState(() {
      _layout = _layout.withPlacement(
        g,
        p.copyWith(offset: p.offset + moved / ControlsConfig.hudScale),
      );
    });
  }

  Widget _piece(HudGroup g, Alignment corner, Widget mock, Size screen) {
    final p = _layout.of(g);
    return Align(
      alignment: corner,
      child: Transform.translate(
        offset: p.offset,
        child: Transform.scale(
          scale: p.scale,
          alignment: corner,
          child: GestureDetector(
            key: _keys[g],
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _chosen = g),
            onPanDown: (_) => setState(() => _chosen = g),
            onPanUpdate: (d) => _drag(g, _delta(g, d), screen),
            onPanEnd: (_) => _save(),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: g == _chosen ? Paw.orange : Paw.cream,
                  width: g == _chosen ? 3 : 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IgnorePointer(child: mock),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A drag's movement on screen. Inside the transforms `delta` is in the
  /// piece's own scale, so it is taken back out here.
  Offset _delta(HudGroup g, DragUpdateDetails d) =>
      d.delta * _layout.of(g).scale * ControlsConfig.hudScale;

  static Widget _circle(IconData icon, {double size = 64}) => PawCircleButton(
    icon: icon,
    tooltip: '',
    size: size,
    borderWidth: 3,
    onPressed: () {},
  );

  Widget _bar(Color color) => Container(
    width: 118,
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: Paw.cream,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Paw.ink, width: 2),
    ),
    child: ColoredBox(color: color),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chosen = _layout.of(_chosen);
    final screen = MediaQuery.sizeOf(context);
    const scale = ControlsConfig.hudScale;
    return Scaffold(
      body: PawBackdrop(
        clouds: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, box) => FittedBox(
                fit: BoxFit.fill,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: box.maxWidth / scale,
                  height: box.maxHeight / scale,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Stack(
                        children: [
                          _piece(
                            HudGroup.topLeft,
                            Alignment.topLeft,
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _circle(Icons.pause_rounded, size: 52),
                                const SizedBox(height: 8),
                                _bar(Paw.red),
                                const SizedBox(height: 3),
                                _bar(const Color(0xFF3B82F6)),
                              ],
                            ),
                            screen,
                          ),
                          _piece(
                            HudGroup.topCentre,
                            Alignment.topCenter,
                            Container(
                              width: 120,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Paw.cream,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Paw.red, width: 2),
                              ),
                            ),
                            screen,
                          ),
                          _piece(
                            HudGroup.topRight,
                            Alignment.topRight,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 190,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Paw.cream,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Paw.ink, width: 2),
                                  ),
                                  child: Text(l10n.hudWind(0), style: Paw.text(14)),
                                ),
                                const SizedBox(width: 10),
                                _circle(
                                  Icons.center_focus_strong_rounded,
                                  size: 52,
                                ),
                              ],
                            ),
                            screen,
                          ),
                          _piece(
                            HudGroup.walk,
                            Alignment.bottomLeft,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _circle(Icons.arrow_back_rounded),
                                const SizedBox(width: 12),
                                _circle(Icons.arrow_forward_rounded),
                              ],
                            ),
                            screen,
                          ),
                          _piece(
                            HudGroup.actions,
                            Alignment.bottomRight,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _circle(Icons.north_east_rounded),
                                const SizedBox(width: 12),
                                _circle(Icons.keyboard_double_arrow_up_rounded),
                                const SizedBox(width: 12),
                                _circle(Icons.star_rounded),
                                const SizedBox(width: 12),
                                Container(
                                  width: 96,
                                  height: 96,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Paw.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Paw.ink, width: 3),
                                  ),
                                  child: Text(
                                    l10n.hudFire,
                                    style: Paw.title(20, weight: 800),
                                  ),
                                ),
                              ],
                            ),
                            screen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.05),
              child: SizedBox(
                width: 340,
                child: PawCard(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.hudEditHint,
                        textAlign: TextAlign.center,
                        style: Paw.text(13),
                      ),
                      Row(
                        children: [
                          Text(l10n.hudEditSize, style: Paw.text(13)),
                          Expanded(
                            child: Slider(
                              min: HudPlacement.minScale,
                              max: HudPlacement.maxScale,
                              value: chosen.scale,
                              activeColor: Paw.orange,
                              onChanged: (v) => setState(() {
                                _layout = _layout.withPlacement(
                                  _chosen,
                                  chosen.copyWith(scale: v),
                                );
                              }),
                              onChangeEnd: (_) => _save(),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: PawButton(
                              label: l10n.hudEditReset,
                              height: 42,
                              fontSize: 14,
                              shadow: 3,
                              padding: 8,
                              onPressed: () {
                                setState(() => _layout = HudLayout.standard);
                                _save();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PawButton(
                              label: l10n.hudDigDone,
                              icon: Icons.check_rounded,
                              fill: Paw.green,
                              height: 42,
                              fontSize: 14,
                              shadow: 3,
                              padding: 8,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
