import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../app/paw_palette.dart';
import '../../config/app_info.dart';
import '../../l10n/app_localizations.dart';
import '../../net/lan.dart';
import '../../services/audio_service.dart';
import '../widgets/paw/paw_backdrop.dart';
import '../widgets/paw/paw_logo.dart';
import '../widgets/paw/paw_widgets.dart';
import 'history_screen.dart';
import 'how_to_play_screen.dart';
import 'lan_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

/// Title screen: the painted pet camp, the wordmark top right, the Play
/// button with How to Play and Settings under it, version and About
/// bottom right.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) {
      AppServices.of(context).audio.play(Sfx.ui);
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return _RejoinOffer(
      child: PopScope(
        canPop: false,
        // The back gesture here would close the app: ask first.
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) confirmQuitApp(context);
        },
        child: Scaffold(
          body: PawBackdrop(
            hills: PawHills.menu,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  SafeArea(
                    child: Stack(
                      children: [
                        // The painting's pets fill the left: the logo goes
                        // over the open sky at the top right, the buttons
                        // down the far right.
                        Positioned(
                          right: 20,
                          top: 10,
                          width: box.maxWidth * 0.36,
                          child: FittedBox(
                            child: PawLogo(title: l10n.appTitle, size: 68),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          top: 90,
                          bottom: 56,
                          width: (box.maxWidth * 0.28).clamp(210, 300),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PawButton(
                                label: l10n.menuPlay,
                                icon: Icons.play_arrow_rounded,
                                fill: Paw.orange,
                                height: 56,
                                fontSize: 26,
                                display: true,
                                borderWidth: 3,
                                radius: 16,
                                onPressed: () => open(const SetupScreen()),
                              ),
                              // No sockets on the web.
                              if (lanSupported) ...[
                                const SizedBox(height: 8),
                                PawButton(
                                  label: l10n.menuPlayWifi,
                                  icon: Icons.wifi_rounded,
                                  fill: Paw.green,
                                  borderWidth: 3,
                                  onPressed: () => open(const LanScreen()),
                                ),
                              ],
                              const SizedBox(height: 8),
                              PawButton(
                                label: l10n.menuHowToPlay,
                                icon: Icons.menu_book_rounded,
                                borderWidth: 3,
                                onPressed: () => open(const HowToPlayScreen()),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: PawButton(
                                      label: l10n.menuHistory,
                                      icon: Icons.history_rounded,
                                      borderWidth: 3,
                                      padding: 4,
                                      fontSize: 13,
                                      onPressed: () =>
                                          open(const HistoryScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PawButton(
                                      label: l10n.menuSettings,
                                      icon: Icons.settings_rounded,
                                      borderWidth: 3,
                                      padding: 4,
                                      fontSize: 13,
                                      onPressed: () =>
                                          open(const SettingsScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 24,
                          bottom: 12,
                          child: Row(
                            children: [
                              Text(
                                'v${AppInfo.version}',
                                style: Paw.text(
                                  12,
                                  weight: 700,
                                  color: Paw.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Once per launch: if the app was closed during a Wi-Fi match this phone
/// was a guest in, offer to go back to it.
class _RejoinOffer extends StatefulWidget {
  const _RejoinOffer({required this.child});
  final Widget child;

  @override
  State<_RejoinOffer> createState() => _RejoinOfferState();
}

class _RejoinOfferState extends State<_RejoinOffer> {
  @override
  void initState() {
    super.initState();
    if (!lanSupported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
  }

  Future<void> _offer() async {
    if (!mounted) return;
    final settings = AppServices.of(context).settings;
    final ticket = settings.rejoinTicket;
    if (ticket == null) return;
    final l10n = AppLocalizations.of(context);
    final back = await showPawConfirm(
      context: context,
      title: l10n.rejoinTitle,
      body: l10n.rejoinBody,
      ok: l10n.rejoinOk,
      cancel: l10n.rejoinForget,
    );
    if (!mounted) return;
    if (!back) {
      settings.rejoinTicket = null;
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => LanScreen(rejoin: ticket)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Quit Pawtillery?" — closes the app only on a yes.
Future<void> confirmQuitApp(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  AppServices.of(context).audio.play(Sfx.ui);
  final quit = await showPawConfirm(
    context: context,
    title: l10n.quitAppTitle,
    body: l10n.quitAppBody,
    ok: l10n.pauseQuit,
    cancel: l10n.dialogCancel,
  );
  if (quit) await SystemNavigator.pop();
}
