import 'package:flutter/material.dart';

import '../../app/field_palette.dart';
import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/weapons.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_lookup.g.dart';
import '../hud/weapon_menu.dart';
import '../widgets/field/ink_icons.dart';
import '../widgets/field/paper.dart';
import '../widgets/field/plate.dart';
import '../widgets/field/stamp.dart';
import '../widgets/field/catalogue.dart';

/// How to Play (PRD: 4–6 illustrated pages) as journal pages: a plate on
/// the left, the text on the right, page numbers at the foot.
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
      body: PaperAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(title: l10n.menuHowToPlay),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    for (final (i, (title, body, art)) in pages.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Center(
                                child: Plate(
                                  number: l10n.plateNumber('${i + 1}'),
                                  child: SizedBox(
                                    width: 220,
                                    height: 150,
                                    child: art,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SpacedTitle(title, size: 20, spacing: 4),
                                    const SizedBox(height: 6),
                                    const LeafRule(width: 120),
                                    const SizedBox(height: 10),
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    InkButton(
                      label: l10n.back,
                      onPressed: _page == 0 ? null : () => _go(-1),
                    ),
                    Expanded(
                      child: Text(
                        '— ${_page + 1} —',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: FieldPalette.inkSoft,
                        ),
                      ),
                    ),
                    last
                        ? StampButton(
                            label: l10n.howDone,
                            minWidth: 120,
                            fontSize: 16,
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        : InkButton(
                            label: l10n.howNext,
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
        size: size,
        engraved: true,
        facing: facing,
      );

  Widget _art(BuildContext context, int page) {
    switch (page) {
      case 0:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const InkIcon(InkGlyph.walkLeft, size: 34),
            _figure(Families.rabbit),
            const InkIcon(InkGlyph.walkRight, size: 34),
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
          child: ColorFiltered(
            colorFilter: engravingFilter,
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
          ),
        );
      case 3:
        return const Center(child: InkIcon(InkGlyph.wind, size: 110));
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

/// Pencil sketch of a slingshot pull: the drag back and the arc forward.
class _AimSketch extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const start = Offset(122, 92);
    final pencil = Paint()
      ..color = FieldPalette.pencil
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, const Offset(52, 132), pencil);
    final ink = Paint()..color = FieldPalette.ink;
    for (var i = 1; i <= 8; i++) {
      final t = i / 8;
      canvas.drawCircle(
        Offset(start.dx + t * 90, start.dy - t * 80 + t * t * 50),
        2.2,
        ink,
      );
    }
    canvas.drawCircle(const Offset(52, 132), 5, pencil);
  }

  @override
  bool shouldRepaint(_AimSketch old) => false;
}
