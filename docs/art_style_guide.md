# Art & UI Style Guide — Pawtillery

Status: **v2 direction "Sunny Brawl"**, chosen by the developer on
2026-10-18. It replaces the v1 field-guide look. The quality bar is a
commercial painted-cartoon artillery game (the developer pointed at
Worms W.M.D as the benchmark for polish). The identity, names, characters,
layouts and assets are our own (PRD: no names, characters, assets or text
from other games).

## Identity in one line

> A Saturday-morning cartoon brawl on a sunny farm: chunky, toy-like,
> warm, loud, and easy to read from arm's length.

Animals are expressive cartoon characters, not specimens. The world is
painted. The interface is made of chunky toy pieces: thick dark outlines,
two-tone fills, gloss bands and solid drop shadows.

## What we borrow and what we don't

The genre's conventions are shared and fine to use: turn-based artillery,
a weapon panel, wind indicator, timer, name and HP labels over units,
a crosshair, destructible terrain, rising water.

What stays **ours**:

| Theirs (don't) | Ours (do) |
|---|---|
| Worms, sheep, banana bombs, holy grenades, concrete donkeys | 13 animal families with their own signature weapons |
| Their logo, fonts, menu layouts, colour palette, HUD art | Lilita One, the Sunny Brawl palette, ribbons and slabs below |
| Their maps and set pieces (e.g. their specific levels) | Our themes: farm, coastal cliffs, snowy mountain |
| Their voice lines and copy | Our own copy (EN/ID) |

## Palette

Defined in `lib/app/toon_palette.dart`; use the names in code.

| Name | Hex | Use |
|---|---|---|
| outline | `#2A1A12` | Every outline, solid drop shadows, text on cream |
| cream / creamShade / creamDeep | `#FFF4DC` / `#F1DDB4` / `#D9B98A` | Menu panels, cards, switches off |
| sun → sunDeep | `#FFC928` → `#F07C0C` | The primary action (Play, Start, Fire), titles' ribbons |
| leaf → leafDeep | `#8BD645` → `#3E9420` | Confirm, healthy, switches on |
| sky → skyDeep | `#5CC8F5` → `#1C76C4` | Secondary actions, selection, back |
| tomato → tomatoDeep | `#FF6A47` → `#C6281A` | Danger, leave, damage, sudden death |
| stone → stoneDeep | `#C9C2B6` → `#8A8276` | Disabled |
| night | `#182230` at 88 % | HUD panels over the arena |
| bark | `#6B4A33` | Secondary text on cream |

Team colours are bright and saturated so labels read over any map:
red `#E8412C`, blue `#2F86E0`, green `#46B52B`, yellow `#F2B705`,
purple `#9B5DE5`, orange `#FF7A1A`.

Fills are always **two-tone** (light on top, deep at the bottom). One
primary (sun) action per screen.

## Typography

- **Lilita One** (SIL OFL, `assets/fonts/`), one weight, for all text.
- Titles, button labels and HUD numbers: white with a dark outline and a
  solid drop (`ToonText`, outline built from text shadows so it stays one
  Text widget).
- Body text on cream: outline colour, no outline effect. Secondary text in
  bark.
- Button labels are upper case; everything else is sentence case.

## Shapes

- Corner radius 12–18 for panels and buttons; circles for icon buttons.
- Outline 2.5–3.5 px, colour `outline`. Never hairlines.
- Depth: buttons sit on a solid dark base 4–5 px deep and sink onto it
  when pressed. Panels cast a soft dark offset shadow (0, 5).
- A gloss band (white, ~30 %) across the top third of buttons and badges.

## Components (`lib/ui/widgets/toon/`)

| Widget | Use |
|---|---|
| `ToonBackdrop` | Painted farm meadow behind every menu (sky, sun, clouds, hills, lollipop trees, flowers) |
| `ToonButton` | Chunky slab button; `tone` picks the colour |
| `ToonRoundButton` | Round icon button; supports hold (walk) |
| `ToonPanel` | Cream card or night HUD panel, optional ribbon title |
| `ToonRibbon` | Title on a ribbon with folded tails |
| `ToonSegmented`, `ToonSwitch` | Form controls |
| `ToonHeader` | Back button + ribbon title + actions |
| `ToonTile`, `showToonPicker` | Picker grids (families, breeds, weapons) |
| `ToonIcon` | Code-drawn icons: white strokes with a dark outline |
| `showToonDialog` | Pause, confirm, pickers: a panel that pops in |

## In the arena

- **HUD:** chunky badges in the corners on night panels: timer (top left,
  in the active team's colour, red and pulsing in the last 5 s), wind
  (top centre, arrow meter), team HP bars, round icon buttons. The middle
  of the screen stays clear.
- **Unit labels:** two small translucent rounded boxes above each unit,
  name on top and HP below, both in bold team-colour text with a dark
  outline. The active unit gets a bouncing arrow.
- **Aim:** a team-coloured crosshair reticle at the aim angle, plus the
  power meter.
- **Weapon panel:** slides in from the right; colour weapon icons on
  cards; ammo as a number badge.

## The W.M.D lesson: painted world, clean characters

Team17 described W.M.D's look as hand-painted landscapes against simpler,
clean-lined characters, deliberately different so players can tell
scenery from what they can interact with. We apply that principle (not
their art):

- **Terrain is painted and soft-edged:** no hard black outline; a soft
  dark crust where ground meets air, brush-stroke texture with warm/cool
  colour drift and wandering strata, a grass or snow fringe painted into
  the air above tops, roots, leaves or icicles hanging under overhangs.
- **Characters are clean and outlined:** flat fills with one shadow
  shape, a thick dark outline, big eyes with heavy upper lids for
  attitude.
- **Backdrops are simple and hazy:** no outlines, so the play layer pops.
- Everything stays drawn in code; no image files.

## Animals

Painted cartoon: big heads (about 45 % of height), large eyes with
highlights and heavy upper lids in the head colour, readable silhouettes,
dark outlines (1.35 px at 1×), one cel shadow shape plus a faint
highlight, a team-colour bandana with polka dots. Long fur is one merged
tufted silhouette. Same API as before (`AnimalArt.draw`, poses).

## Maps

Set pieces, not flat strips: islands with overhangs, caves and props
built into the terrain. Each theme has its own parallax backdrop.

| Theme | Terrain | Props |
|---|---|---|
| Farm | soil (embedded stones), hay, plank wood, roof shingles, leaf clumps | barn, haystacks, fences, water tower |
| Coastal cliffs | stacked boulders, sand, timber | lighthouse, pier, beached boat, rocks, sea |
| Snowy mountain | stacked boulders, snow, ice, logs | pines, cabin, icicles, frozen lake |

## Effects

Big readable explosions: a flash, a fireball, additive embers, a lingering
smoke column, and debris tinted by the terrain material that was hit.
