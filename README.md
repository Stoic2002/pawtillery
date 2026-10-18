# Pawtillery

Turn-based 2D animal artillery game for Android (Flutter + Flame), local
hotseat for 2–4 players. Working title.

## Layout

- `lib/sim/` — deterministic simulation, pure Dart (no Flutter/Flame imports).
- `lib/game/` — Flame rendering of the sim state, camera, effects.
- `lib/ui/` — Flutter screens and HUD overlays.
- `lib/config/` — all balancing numbers and game data.
- `lib/l10n/` — `app_en.arb`, `app_id.arb`.
- `docs/decisions.md` — design decisions not covered by the PRD.

## Develop

Flutter 3.41.7 (fvm). Local CI (codegen, analyze, tests):

```bash
./tool/ci.sh
```

Run on a connected Android device:

```bash
~/fvm/versions/3.41.7/bin/flutter run
```
