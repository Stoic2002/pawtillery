# Art & UI Style Guide — Pawtillery

Status: **v5 "Redesign prototype"**, 2026-10-19. The developer designed the
game in `redesign/` (Claude Design exports) and chose:
`Pawtillery.dc.html` for the menus, setup and HUD, and
`ArenaScene.dc.html` for the arena look, with `PetSoft.dc.html` for the
pets. Everything stays drawn in code; no image assets (fonts only).

## Identity in one line

> Cosy, bold and friendly: cream cards with thick brown outlines and solid
> shadows over a blue sky, chibi pets with team collars, and a painted
> backyard battlefield at dusk.

## Tokens (`lib/app/paw_palette.dart`)

| Name | Hex | Use |
|---|---|---|
| ink | `#2B2118` | Outlines, solid shadows, text |
| cream | `#FFF6E6` | Cards, buttons, pills |
| peach / peachLight | `#FFE7C2` / `#FFEFD6` | Selected rows, chips, wells, dividers, stripes |
| orange / orangeDeep | `#FF8A3D` / `#E2681C` | The one primary action (Play, Start match, Fire, Done) |
| green | `#4CBF6B` | Confirm, Randomize, Next, switches on |
| yellow | `#F5B700` | Last 10 s, strong wind, stars, retreat |
| red / redText | `#E5484D` / `#B4232A` | Danger (delete, quit) |
| muted | `#6B5B4B` | Secondary text |
| line | `#CFC4B3` | Disabled |
| skyTop → skyBottom | `#7CC8FF` → `#D8F0FF` | Menu sky |
| hill / hillLight | `#8FD67A` / `#B9E49B` | Menu hills |

Teams (`lib/config/teams.dart`): red `#E5484D` ●, blue `#3B82F6` ▲,
green `#22A559` ■, purple `#8B5CF6` ★ (plus yellow ◆ and orange ♥).
Every team shows its mark next to its colour.

## Type

- **Baloo 2** (SIL OFL) for titles and big numbers (weights 700–800).
- **Nunito** (SIL OFL) for everything else (600–800).
- Icons: Material rounded icons (bundled with Flutter), filled.

## Shapes

- Cards: radius 20, 3 px ink outline, solid 4 px ink shadow.
- Buttons: radius 14–16, 2–3 px outline, 3–4 px shadow; pressed, they
  drop onto the shadow. Round buttons 44–64 px, Fire 80 px.
- Pills: fully rounded toggles (the chosen option is an ink pill with
  cream text), chips with a 2 px outline.

## Components (`lib/ui/widgets/paw/`)

`PawButton`, `PawCircleButton` (also hold-to-walk), `PawIconBox`,
`PawCard`, `PawPillToggle`, `PawStepper`, `PawSwitch`, `PawSlider`,
`TeamBadge` + `TeamSymbolPainter`, `PawIconChip`, `PawHeader`,
`showPawDialog`, `showPawConfirm`, `PawBackdrop` (sky, clouds, hills),
`PawLogo` (orange Baloo 2 with an ink outline and a paw for the dot of
the i), `PetFigure`, `StripesPainter`.

## Screens (as in the prototype)

- **Menu:** logo top left, pets on the green hill, Play / How to Play /
  Settings on the right, version and About (a card) bottom right.
- **Setup:** Teams tab (a card per team with a name field, ⋮ menu to
  randomize or delete, unit rows that open the unit editor, an
  "Add team" card) and Rules tab (steppers, pill toggles, map cards);
  a bottom bar with the summary and Start match.
- **Unit editor:** portrait, name, Randomize; family tiles, breed chips,
  passive and signature notes; Done.
- **Settings, How to Play, Pause, Results** follow the prototype.

## Arena (`ArenaScene.dc.html`)

- **HUD:** pause and team HP pills top left; the timer pill (yellow and
  pulsing under 10 s) with the active unit's chip top centre; the wind
  pill and the camera button top right; walk buttons bottom left; jumps,
  the weapon button (with ammo) and Fire bottom right; an aim pill with
  Cancel, angle and power while aiming; Cancel/Confirm for target
  weapons; the team banner slides in at each turn start; the tutorial
  card counts "1 / 4".
- **Unit tags:** a dark translucent tag (team mark, name, HP, thin HP
  bar; HP turns red at 25 or less), a cream arrow over the active unit,
  a small gravestone with a team band where a unit fell.
- **Aim:** a dashed circle around the unit, cream dots for the path, and
  an "angle · power" pill.
- **Pets:** PetSoft chibis: round body with a soft radial shade, family
  features, glossy eyes, blush, a team collar with a gold tag.
- **Terrain:** soil that darkens with depth, stones and fine roots, a
  dark band under the grass mat, grass blades in four tints, a warm rim
  light along the top (`MapDef.rimArgb`), soft dark crust at edges.

## Maps

Set pieces, not flat strips: islands with overhangs, caves and props
built into the terrain. Each theme has its own sky, weather and parallax
backdrop, and an **ambient light** (`MapDef.ambientArgb`) multiplied into
the terrain, decorations and debris, never into the units.

| Theme | Light | Terrain | Props | Sky |
|---|---|---|---|---|
| Backyard (the redesign's arena) | warm dusk, rim light | soil with stones and roots, grass blades in four tints, toy blocks, tin can | lettered toy blocks, a tin can, a puddle | dusk gradient, low sun glow, stars, pink clouds, house and trees, fence with fairy lights and bokeh |
| Haunted Keep | cold moonlight | soil, stacked boulders, castle stone, slate | castle with towers, keep and dungeon, broken drawbridge, moat, graveyard, crypt, dead trees | stars, moon, dark clouds, bats, far castles, fog |
| Shipwreck Cove | storm grey | stacked boulders, sand, ship timber | broken lighthouse, sea cave, galleon broken in two on a sandbar, island lookout | storm clouds, lightning, rain, rock stacks, a ghost ship |
| Ruined Village | fire glow | soil, rubble, brick, timber | bombed church and spire, smashed houses, sandbags, flooded crater, cellar | burning skyline, smoke columns, low red sun, embers |

**Terrain edges are antialiased** (coverage alpha on edge pixels, bilinear
filtering, a 2 px gutter per chunk so filtering has no seams).

**Water** has two layers: a dark swell behind the terrain so islands sit
in the sea, and a front layer that is clear near the surface and deep
below, with a rolling surface, lit crest, shadowed trough, foam and
drifting caustics.

## Effects

Big readable explosions: a flash, a fireball, additive embers, a lingering
smoke column, and debris tinted by the terrain material that was hit.
