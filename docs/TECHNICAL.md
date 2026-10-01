# Runtime design

The module reads local mission preview data and draws its own GUI panel. It
does not modify the game's widgets, gameplay memory or networking. The
supported executable and game module hashes are enforced at startup.

## Mission inputs

`mission.lua` resolves the highlighted mission's enemy tags the way the game
does: the mission seed and difficulty tables, campaign and operation
modifiers, level tags and exclusion rules. From the same campaign rows it also
collects spawn-weight modifiers (category 72) and war effects (type 15) that
apply to the hovered planet. Hosted previews use the highlighted operation's
planet, even if the ship's active operation is elsewhere. Remote previews
require matching advertisement and loaded preview packets. The reader withholds
incomplete or stale reports. Briefing uses the selected mission descriptor and
its matching controller.

## Roster

`roster_data.lua` is generated from the supported build's faction tables: unit
rows, replacement rules and spawn groups for patrols, reinforcements,
garrisons, border travellers and air support. Unit names and size classes
follow the Helldivers Wiki. `roster.lua` replays the native rules for one
mission (group eligibility, weights, modifiers, replacement chains) and
returns the large enemies with meter levels and the rest in order. See
[how the forecast is built](CONSTELLATIONS.md).

The roster runs only when the mission's faction, difficulty, tags or
modifiers change; refreshes of the same mission reuse it. Its functions are
kept interpreted (`jit.off`), so they add no traces to the game's shared
LuaJIT code cache.

## Panel

`panel.lua` draws a gold-framed box with retained GUI objects in the active
locale's native body font. It hangs below the native planet, operation or
briefing panel, sharing its bottom stroke, and may extend over the squad list
down to the bottom prompt row. GUI layers sort across every GUI in the
world, only 0-1023 sort correctly, and the squad nameplates draw above
1000, so the box draws on layers 1011-1015. Like the native frame, a 3-unit gold outline surrounds a 4-unit
dark gap, then the opaque body; text starts 22 units in. The body and slate
colours are set darker than the native ones because the war-table UI shows
dark colours lighter than their values; on screen they read as #0F141E and
#3B4654. Text steps down from 18 to 12 units if needed. Only when a native
panel ends too close to the prompt row does the box move beside it, and only
there may enemies be summarised as "and N more".

The headline is always one line at the title size. A headline wider than the
panel scrolls like the game's long strings: it holds at the start for 2 s,
scrolls at 40 units/s, holds at the end for 1.5 s, then resets. Carets are
measured once per report, one per character (never per byte), and the
scrolling window always starts and ends between characters. Panel-coloured
masks over the side padding (layer 1015) hide glyphs entering or leaving the
text column.

Unchanged reports make no GUI calls, with one exception. While a long
headline is moving, each frame makes one text update. It makes none while
the headline holds at either end.

Panel placement and visibility follow the native frame: briefing visibility
follows the native tab and inherited opacity, the forecast hides during pod
entry and on the loadout screen, and remote selection activity hides it
immediately after unhover.

## Text and translations

Every text is in `locales/en.lua`: captions, the 31 constellation titles and
the 80 enemy names under keys made from their roster names
(`unit.mg_raiders`). `src/bingus_text.lua`, shared byte-for-byte with the
other CowboyBingus mods that show text, resolves each key for the current
language: English, then a bundled translation (`locales/<tag>.lua`, embedded
by the build after `scripts/translations.py check` passes), then translation
packs registered in `_G.BingusTranslations`. Each translated text is checked
(valid UTF-8, no control characters, the same `{placeholders}` as English);
a refused text stays English and the log says why.

The language is the game's own Text Language: the settings object at
`[game.dll+0x3326340] + 705500` holds at +212 an index into the table of
language records at `game.dll+0x37C5650`, whose code string is at +8 (`us`
for English). The mod reads it when the forecast first appears and again
when the native body font changes, which is what a language change does. If
the read fails, it uses Steam's language for the game, then English. Texts
are resolved on the 0.5 s refresh, and every drawn text is part of the
report signature, so a language change redraws the panel.

The panel measures, wraps and scrolls by character. Lines break at spaces and
between Chinese or Japanese characters, never before closing punctuation or
after opening punctuation. The list separator and "and N more" come from the
translation. The panel draws with the game's font for its current Text
Language, which may not contain other scripts: that is why the forecast
follows the game's language rather than a separate setting.

## Per-frame cost

`tests/test_budget.lua` counts the game reads each frame makes with the real
installer and readers: 2 on the ship, 16 with the war table open (64 on the
0.5 s refresh of a highlighted mission), 18 on the briefing (68 on refresh)
and 5 on the loadout screen. These equal v3.16.1's counts. Reading the Text
Language adds 5 reads on the first frame the forecast appears and on a frame
where the native font changed, never on the frames counted above. The mod
never queries memory protection and never writes game memory.

## Exported roster

Other mods can preview a forecast through `EnemyIntelligence.roster`, which
is set when the module loads, before the first frame and before the build
check. It reads no memory and draws nothing:

- `api`: `1`. Fields are only added under this number; a change to an
  existing one raises it.
- `build`: the Steam build `roster_data.lua` was generated from. Compare it
  with your own supported build before trusting the result.
- `from_native(tag)`: native enemy tag (0-31) to the tag IDs below.
- `title(tag)`: the English headline title of a tag, or nil.
- `forecast(snapshot, zone, war)`: `snapshot` is `{faction=2|3|4,
  difficulty=1..10, tags={...}}` with converted tag IDs; `zone` and `war` are
  optional family hash to multiplier maps, as `mission.lua` collects them.
  Returns `{large={{name=, ticks=}, ...}, small={name, ...}}` with English
  unit names, ordered as the panel shows them. Invalid input raises, so call
  it with `pcall`.

The export keeps its own one-entry cache, so callers never evict the panel's
forecast. Check `status` too: a value starting with `disabled:` means the
game build is unsupported and the panel shows nothing.

## Compatibility

The public name is Know Your Constellation. The legacy module identifier
`mods/cowboybingus/enemy_intelligence`, global EnemyIntelligence guard and
manager GUID stay stable for compatibility with existing installations.

Public memory fixtures are constructed from fictional address ranges and
synthetic packets. Static offsets, resource hashes and regression semantics
are retained without publishing session data or personal identifiers.
