# Art & UI Style Guide — Pawtillery

Status: **v4 "Iron & Dusk"**, 2026-10-19. Moody painted worlds (v3),
with a dark-fantasy UI of iron and brass and semi-realistic animals,
chosen by the developer after finding the toon UI too cartoony and the
cartoon faces ugly. The quality bar is a
commercial painted-cartoon artillery game (the developer pointed at
Worms W.M.D as the benchmark for polish). The identity, names, characters,
layouts and assets are our own (PRD: no names, characters, assets or text
from other games).

## Identity in one line

> Animals at war in haunted, stormy, burning places: dark painted worlds,
> a forged iron-and-brass interface, animals drawn with natural anatomy.

## What we borrow and what we don't

The genre's conventions are shared and fine to use: turn-based artillery,
a weapon panel, wind indicator, timer, name and HP labels over units,
a crosshair, destructible terrain, rising water.

What stays **ours**:

| Theirs (don't) | Ours (do) |
|---|---|
| Worms, sheep, banana bombs, holy grenades, concrete donkeys | 13 animal families with their own signature weapons |
| Their logo, fonts, menu layouts, colour palette, HUD art | Cinzel and Alegreya, iron and brass, engraved titles |
| Their maps and set pieces (e.g. their specific levels) | Our themes: haunted keep, shipwreck cove, ruined village |
| Their voice lines and copy | Our own copy (EN/ID) |

## Palette

Defined in `lib/app/iron_palette.dart`; use the names in code.

| Name | Hex | Use |
|---|---|---|
| ink | `#0B0B0D` | Outer edges, shadows, text on brass |
| iron / ironShade / ironEdge | `#24262B` / `#1A1B1F` / `#3A3D44` | Panels, plates, quiet borders |
| brass / brassDeep / brassLight | `#C9A45C` / `#7E602C` / `#EBD49A` | Trims, titles, the primary action |
| moss | `#6E8E52` | Confirm, healthy, switches on |
| steel | `#6E8296` | Secondary accents |
| blood | `#B8442E` | Danger, damage, leave, Fire |
| ash | `#55555A` | Disabled |
| night | `#141518` at 85 % | HUD panels over the arena |
| parchment / mute | `#EDE3CC` / `#A39A88` | Text on iron; secondary text |

Team colours stay bright so units read over dark maps.

## Typography

- **Cinzel** (variable, SIL OFL) for titles, button labels and HUD
  numbers, weight 700–900, capitals, letter-spaced; an engraved shadow
  (`IronText`), never a thick outline.
- **Alegreya** (variable, SIL OFL) for reading: body text, form labels,
  descriptions.
- Unit name and HP labels in the arena use Cinzel too.

## Shapes

- Square-ish corners (0–6 px). Fine lines: 1–2 px brass trims, 1 px dark
  edges. No gloss bands, no chunky slabs, no ribbons with tails.
- Plates carry rivets in the corners; panels a fine inlay and brass
  corner brackets.
- Soft blurred shadows under plates and panels.

## Components (`lib/ui/widgets/iron/`)

| Widget | Use |
|---|---|
| `IronBackdrop` | A battlefield at dusk behind every menu |
| `IronButton` | Forged plate, brass trim, Cinzel label; `tone` picks the metal |
| `IronRoundButton` | Round iron stud with a brass ring; supports hold (walk) |
| `IronPanel` | Iron plate (menus) or translucent night (HUD), inlay, brackets, optional engraved title |
| `IronRibbon` | A title engraved between ornamental rules, on a small plate |
| `IronSegmented`, `IronSwitch` | Form controls |
| `IronHeader` | Back stud + engraved title + actions |
| `IronTile`, `showIronPicker` | Picker grids |
| `IronIcon` | Code-drawn line icons with an engraved shadow |
| `IronLogo` | Brass-cast wordmark and paw medallion |
| `showIronDialog` | Pause, confirm, pickers |

## In the arena

- **HUD:** small iron plaques in the corners: the turn plaque with the
  team name and a serif timer (blood red in the last 5 s), a thin wind
  gauge, thin team HP bars, iron studs for buttons, a round blood-iron
  Fire button. The middle of the screen stays clear.
- **Unit labels:** name and HP in Cinzel, team colour, on dark
  translucent tags; a bouncing arrow over the active unit.
- **Aim:** a crosshair in the team colour with a ring that fills with
  power.

## The W.M.D lesson: painted world, readable characters

The world is painted and soft-edged; units stay the most readable thing
on screen (bright team colours, clear silhouettes, a crisp edge). Backdrops
are simple and hazy. Everything stays drawn in code; no image files.

## Animals

Semi-realistic and painted: natural proportions (head about 30 % of the
height), an anatomical quadruped body (deep chest, dipped back, tucked
belly, haunches), tapering legs with a joint, small almond eyes with an
iris, pupil, one highlight and a fine lid line, soft radial shading,
fine fur strokes, a soft fuzzy rim for long-haired breeds, a thin edge in
a darker shade of the coat (not black), and a collar with a brass tag in
the team colour. Same API (`AnimalArt.draw`, poses).

## Maps

Set pieces, not flat strips: islands with overhangs, caves and props
built into the terrain. Each theme has its own sky, weather and parallax
backdrop, and an **ambient light** (`MapDef.ambientArgb`) multiplied into
the terrain, decorations and debris, never into the units.

| Theme | Light | Terrain | Props | Sky |
|---|---|---|---|---|
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
