import 'package:flutter/material.dart';

import '../../app/iron_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/weapons.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../hud/weapon_menu.dart';
import '../widgets/iron/iron_backdrop.dart';
import '../widgets/iron/iron_button.dart';
import '../widgets/iron/iron_controls.dart';
import '../widgets/iron/iron_icons.dart';
import '../widgets/iron/iron_panel.dart';
import '../widgets/iron/iron_text.dart';

/// How to Play (PRD: 4–6 illustrated pages): a picture card on the left,
/// the text card on the right, page dots at the foot.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) => _controller.animateToPage(
    _page + delta,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (l10n.howMoveTitle, l10n.howMoveBody, _art(context, 0)),
      (l10n.howAimTitle, l10n.howAimBody, _art(context, 1)),
      (l10n.howWeaponsTitle, l10n.howWeaponsBody, _art(context, 2)),
      (l10n.howWindTitle, l10n.howWindBody, _art(context, 3)),
      (l10n.howFamiliesTitle, l10n.howFamiliesBody, _art(context, 4)),
      (l10n.howWinTitle, l10n.howWinBody, _art(context, 5)),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      body: IronBackdrop(
        dim: 0.15,
        child: SafeArea(
          child: Column(
            children: [
              IronHeader(title: l10n.menuHowToPlay.toUpperCase()),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    for (final (title, body, art) in pages)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Center(
                                child: IronPanel(
                                  style: IronPanelStyle.night,
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 230,
                                    height: 156,
                                    child: art,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: IronPanel(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  14,
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      IronText(
                                        title.toUpperCase(),
                                        size: 24,
                                        color: IronPalette.brass,
                                        textAlign: TextAlign.start,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    IronButton(
                      label: l10n.back,
                      tone: IronTone.steel,
                      fontSize: 16,
                      height: 44,
                      onPressed: _page == 0 ? null : () => _go(-1),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < pages.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              width: i == _page ? 26 : 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? IronPalette.brass
                                    : IronPalette.iron,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: IronPalette.ink,
                                  width: 2.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    last
                        ? IronButton(
                            label: l10n.howDone,
                            icon: IronGlyph.check,
                            tone: IronTone.moss,
                            fontSize: 16,
                            height: 44,
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : IronButton(
                            label: l10n.howNext,
                            tone: IronTone.steel,
                            fontSize: 16,
                            height: 44,
                            onPressed: () => _go(1),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _figure(FamilyDef f, {double size = 120, int facing = 1}) =>
      AnimalFigure(
        familyId: f.id,
        breedId: Breeds.ofFamily(f.id).first.id,
        teamArgb: 0xFF2F86E0,
        size: size,
        facing: facing,
      );

  Widget _art(BuildContext context, int page) {
    switch (page) {
      case 0:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const IronIcon(IronGlyph.walkLeft, size: 34),
            _figure(Families.rabbit),
            const IronIcon(IronGlyph.walkRight, size: 34),
          ],
        );
      case 1:
        return Stack(
          children: [
            Positioned(left: 60, top: 20, child: _figure(Families.cat)),
            Positioned.fill(child: CustomPaint(painter: _AimSketch())),
          ],
        );
      case 2:
        return Center(
          child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final w in [
                  Weapons.rock,
                  Weapons.grenade,
                  Weapons.cluster,
                  Weapons.mine,
                  Weapons.boneBoomerang,
                  Weapons.coconut,
                ])
                  WeaponIcon(weapon: w, size: 52),
              ],
            ),
        );
      case 3:
        return const Center(child: IronIcon(IronGlyph.wind, size: 110));
      case 4:
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final f in [
                Families.cat,
                Families.dog,
                Families.bird,
                Families.turtle,
                Families.goat,
                Families.monkey,
              ])
                Tooltip(
                  message: l10n.byKey(f.latinKey),
                  child: _figure(f, size: 66),
                ),
            ],
          ),
        );
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _figure(Families.dog, size: 110),
            _figure(Families.duck, size: 90, facing: -1),
          ],
        );
    }
  }
}

/// A slingshot pull: the drag back and the dotted arc forward.
class _AimSketch extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const start = Offset(122, 92);
    final pencil = Paint()
      ..color = IronPalette.parchment
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, const Offset(52, 132), pencil);
    final ink = Paint()..color = IronPalette.brass;
    for (var i = 1; i <= 8; i++) {
      final t = i / 8;
      canvas.drawCircle(
        Offset(start.dx + t * 90, start.dy - t * 80 + t * t * 50),
        3.4,
        ink,
      );
    }
    canvas.drawCircle(const Offset(52, 132), 5, pencil);
  }

  @override
  bool shouldRepaint(_AimSketch old) => false;
}
