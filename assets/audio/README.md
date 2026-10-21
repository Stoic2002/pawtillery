# Audio

Every sound here is synthesized in code by `tool/audio/generate_audio.dart`
(no samples, no third-party audio). Regenerate after changing it:

    fvm dart run tool/audio/generate_audio.dart

The game picks files up by name; a missing file is simply silent.
Supported: `.ogg`, `.mp3`, `.wav`. Effects are short WAVs; the music loops
are Ogg Vorbis, which Android loops without a gap.

| File | Plays when |
| --- | --- |
| `sfx_fire` | A weapon is fired or used |
| `sfx_explosion` | Something explodes |
| `sfx_jump` | A unit jumps |
| `sfx_hit` | A unit takes damage |
| `sfx_death` | A unit is knocked out |
| `sfx_turn` | A new turn starts |
| `sfx_ui` | A button is pressed |
| `sfx_laser` | The Laser Pointer fires |
| `sfx_thunder` | Thunder Cloud strikes (before its blast) |
| `sfx_shotgun` | Each Shotgun shot (blast and pump) |
| `sfx_nuke` | The Mini Nuke goes off (under the usual explosion) |
| `sfx_gas` | Poison gas is released |
| `sfx_freeze` | An Ice Bomb bursts |
| `sfx_shieldUp` | A Shield Bubble goes up |
| `sfx_shieldPop` | A Shield Bubble pops (blocks a hit or runs out) |
| `sfx_heal` | A First-Aid Kit or health crate heals |
| `sfx_ignite` | Napalm sets the ground on fire |
| `sfx_grapple` | The Grappling Hook is shot (rope and hook) |
| `sfx_meteor` | Meteor Shower is called (the meteors falling) |
| `music_menu` | Menus (loops; C major, 100 BPM, 16 bars) |
| `music_match` | During a match (loops; D minor, 120 BPM, 16 bars) |

List any third-party file added later in `assets/CREDITS.md` with its
licence.
