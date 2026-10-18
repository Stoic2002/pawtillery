# Art & UI Style Guide — Pawtillery

Status: **v1 direction**, chosen by the developer on 2026-10-18 (concept
"Naturalist's field guide"). Every screen follows this; when in doubt,
choose the quieter option.

## Identity in one line

> A naturalist's field journal that went to war: cream paper, engraved ink,
> specimen labels and rubber stamps, in plain daylight.

The animals are observed, catalogued and taken seriously, which is what
makes the chaos funny. Nothing glows, nothing is glass, nothing is neon.

## Palette

Defined in `lib/app/field_palette.dart`; use the names in code.

| Name | Hex | Use |
|---|---|---|
| paper | `#EFE6D2` | Pages, panels, labels |
| paperShade | `#E2D5BA` | Recessed areas, alternate rows |
| paperEdge | `#C9B48E` | Aged edges, deckle, tape shadow |
| ink | `#2B2620` | Text, rules, engraved lines |
| inkSoft | `#5A5146` | Secondary text, captions |
| pencil | `#8E867A` | Hints, disabled, faint guides |
| stamp | `#A8342A` | The one primary action per screen, damage, "Fire" |
| moss | `#4F6B3A` | Ready, valid, healthy |
| tape | `#E8D9A8` (70 %) | Masking tape holding paper to the scene |

Team inks (stamps, collars, HP tallies) are printer's inks, never neon:
vermilion `#B23A2E`, prussian `#2F4F7F`, sap `#4F6B3A`, ochre `#B8862B`,
violet `#5E4A78`, umber `#8A4E2B`.

Rules of thumb: paper and ink carry the screen; stamp red appears at most
once per screen and always means "do it" or "it hurt". No gradients on UI,
no glow, no drop shadows except paper's own thin contact shadow.

## Typography

- **Old Standard TT** (19th-century book face, SIL OFL, bundled in
  `assets/fonts/`) for all text. One weight: no bold anywhere.
- **Titles:** uppercase with wide letter-spacing (3–6), the closest this
  face gets to small caps.
- **Latin names and asides:** italic (*Felis catus*, *Capra hircus*).
- **Numbers** that must be read fast (timer, HP, ammo) use the same face at
  a larger size, never a second font.

## Shapes and lines

- Square corners (0–2 px). Rounded pills only for specimen tags.
- Hairline ink rules (1 px) and double rules (1 px + 0.5 px, 2 px apart)
  for frames. Ornament between rules: a small engraved leaf.
- Paper panels sit very slightly askew (±0.6–1°) and are held by tape or a
  pin; never more than one tilted panel per cluster.

## Components

| Element | Treatment |
|---|---|
| Every menu screen | Paper page with fibre grain and a warm vignette (`PaperAtmosphere`) |
| Main menu | Journal spread: title, italic subtitle, leaf rule, a table of contents for the actions; an engraved plate of animals opposite |
| Primary button | A rubber stamp: stamp-red double border, uppercase spaced text, slightly worn ink, a hair of rotation |
| Other buttons | Ink-outlined labels, or table-of-contents entries with dot leaders |
| Setup | A field roster: one specimen entry per unit (engraved portrait, common name, *Latin name*, breed, name on a tag); pickers open a catalogue of plates, never a dropdown |
| Team | An index tab and a stamp in the team's ink |
| HUD | Field notes taped to the edges: turn slip, wind note, tally of team HP; round paper tokens with ink icons |
| Weapon menu | Catalogue plates with an engraved figure, name in spaced capitals, ammo as tally marks |
| Dialogs | A sheet of paper, askew, taped at the top |
| Results | A field report with the winner stamped across it |
| Icons | Drawn in ink in code (`lib/ui/widgets/ink_icons.dart`); no Material icons on screen |

## In the arena

The world stays painted and semi-realistic (animals, maps, weapons); only
the interface is paper and ink, like notes laid over a photograph. Keep the
arena readable: light vignette only, no grain over gameplay.

Unit labels are small paper tags: name in ink, HP in the team's ink.

## Copy voice

Dry, observational field-guide tone: "Plate IV — *Capra hircus*",
"Observed: 3 turns", "Field report No. 12". Never exclamation marks in
UI chrome. Indonesian copy keeps the same tone.
