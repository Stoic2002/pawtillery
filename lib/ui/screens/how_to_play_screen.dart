import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/breeds.dart';
import '../../config/families.dart';
import '../../config/teams.dart';
import '../../config/weapons.dart';
import '../../l10n/app_localizations.dart';
import '../hud/weapon_menu.dart';
import '../widgets/unit_avatar.dart';

/// How to Play (PRD: 4–6 halaman bergambar tentang kontrol dan aturan).
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (l10n.howMoveTitle, l10n.howMoveBody, const _MoveArt()),
      (l10n.howAimTitle, l10n.howAimBody, const _AimArt()),
      (l10n.howWeaponsTitle, l10n.howWeaponsBody, const _WeaponsArt()),
      (l10n.howWindTitle, l10n.howWindBody, const _WindArt()),
      (l10n.howFamiliesTitle, l10n.howFamiliesBody, const _FamiliesArt()),
      (l10n.howWinTitle, l10n.howWinBody, const _WinArt()),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuHowToPlay)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final (title, body, art) in pages)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Center(child: art)),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                  const SizedBox(height: 12),
                                  Text(body,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _page == 0
                        ? null
                        : () => _controller.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut),
                    child: Text(l10n.back),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: last
                        ? () => Navigator.of(context).pop()
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut),
                    child: Text(last ? l10n.howDone : l10n.howNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- illustrations

int get _red => Teams.styles[0].colorArgb;

Widget _avatar(BuildContext context, FamilyDef f, {double size = 72}) =>
    UnitAvatar(
      familyId: f.id,
      breedId: Breeds.ofFamily(f.id).first.id,
      teamArgb: _red,
      size: size,
    );

class _MoveArt extends StatelessWidget {
  const _MoveArt();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_left, size: 56),
          _avatar(context, Families.rabbit, size: 96),
          const Icon(Icons.arrow_right, size: 56),
          const Icon(Icons.keyboard_double_arrow_up, size: 40),
        ],
      );
}

class _AimArt extends StatelessWidget {
  const _AimArt();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        height: 160,
        child: Stack(
          children: [
            Positioned(left: 70, top: 50, child: _avatar(context, Families.cat)),
            Positioned.fill(child: CustomPaint(painter: _SlingshotPainter(
                Theme.of(context).colorScheme.primary))),
            const Positioned(
              left: 18,
              top: 104,
              child: Icon(Icons.touch_app, size: 40),
            ),
          ],
        ),
      );
}

class _SlingshotPainter extends CustomPainter {
  _SlingshotPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pull = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3;
    final dots = Paint()..color = color;
    const unit = Offset(106, 92);
    // Finger pulled back to bottom-left …
    canvas.drawLine(unit, const Offset(38, 124), pull);
    // … the shot goes up and to the right.
    for (var i = 1; i <= 7; i++) {
      final t = i / 7;
      final x = unit.dx + t * 100;
      final y = unit.dy - t * 90 + t * t * 55;
      canvas.drawCircle(Offset(x, y), 4, dots);
    }
  }

  @override
  bool shouldRepaint(_SlingshotPainter old) => old.color != color;
}

class _WeaponsArt extends StatelessWidget {
  const _WeaponsArt();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final w in [
            Weapons.rock,
            Weapons.grenade,
            Weapons.cluster,
            Weapons.mine,
            Weapons.teleport,
            Weapons.coconut,
          ])
            WeaponIcon(weapon: w, size: 52),
        ],
      );
}

class _WindArt extends StatelessWidget {
  const _WindArt();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: math.pi / 2,
            child: const Icon(Icons.navigation, size: 64),
          ),
          const Icon(Icons.air, size: 72),
          const Icon(Icons.timer_outlined, size: 40),
        ],
      );
}

class _FamiliesArt extends StatelessWidget {
  const _FamiliesArt();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          for (final f in Families.all) _avatar(context, f, size: 56),
        ],
      );
}

class _WinArt extends StatelessWidget {
  const _WinArt();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events,
              size: 88, color: Theme.of(context).colorScheme.tertiary),
          const Icon(Icons.pinch_outlined, size: 40),
        ],
      );
}
