import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/paw/paw_widgets.dart';
import 'hud_layout.dart';

/// Over the paused match's HUD: a frame around each part, to drag it, and for
/// the chosen one a slider for its size. Saved as it changes.
class HudEditor extends StatefulWidget {
  const HudEditor({super.key, required this.keys, required this.onDone});

  /// Finds each part on screen.
  final Map<HudGroup, GlobalKey> keys;
  final VoidCallback onDone;

  @override
  State<HudEditor> createState() => _HudEditorState();
}

class _HudEditorState extends State<HudEditor> {
  HudGroup _chosen = HudGroup.actions;

  Rect? _rectOf(HudGroup g) {
    final box = widget.keys[g]?.currentContext?.findRenderObject();
    final me = context.findRenderObject();
    if (box is! RenderBox || me is! RenderBox || !box.hasSize) return null;
    return Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: me),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: me),
    );
  }

  void _drag(HudGroup g, Offset delta, Size bounds) {
    final settings = AppServices.of(context).settings;
    final rect = _rectOf(g);
    if (rect == null) return;
    // Stays on screen.
    final moved = Offset(
      delta.dx.clamp(-rect.left, bounds.width - rect.right),
      delta.dy.clamp(-rect.top, bounds.height - rect.bottom),
    );
    final layout = settings.hudLayout;
    final p = layout.of(g);
    settings.hudLayout = layout.withPlacement(
      g,
      p.copyWith(offset: p.offset + moved),
    );
  }

  @override
  void initState() {
    super.initState();
    // The frames need the parts laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;
    return LayoutBuilder(
      builder: (context, box) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          // Frames follow the parts, a frame after they moved.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          final layout = settings.hudLayout;
          return Stack(
            children: [
              const Positioned.fill(
                child: AbsorbPointer(child: ColoredBox(color: Color(0x552B2118))),
              ),
              for (final g in HudGroup.values)
                if (_rectOf(g) case final rect?)
                  Positioned.fromRect(
                    rect: rect.inflate(4),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => setState(() => _chosen = g),
                      onPanStart: (_) => setState(() => _chosen = g),
                      onPanUpdate: (d) =>
                          _drag(g, d.delta, box.biggest),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: g == _chosen ? Paw.orange : Paw.cream,
                            width: g == _chosen ? 3 : 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              Align(
                alignment: const Alignment(0, 0.15),
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
                                value: layout.of(_chosen).scale,
                                activeColor: Paw.orange,
                                onChanged: (v) =>
                                    settings.hudLayout = layout.withPlacement(
                                      _chosen,
                                      layout.of(_chosen).copyWith(scale: v),
                                    ),
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
                                onPressed: () =>
                                    settings.hudLayout = HudLayout.standard,
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
                                onPressed: widget.onDone,
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
          );
        },
      ),
    );
  }
}
