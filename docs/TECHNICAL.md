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
installer and readers: 2 on the ship and in missions, 16 with the war table
open (64 on the 0.5 s refresh of a highlighted mission, with or without spawn
weights and war effects), 30 while hovering another squad's joinable mission
(99 on refresh), 18 on the briefing (68 on refresh) and 5 on the loadout
screen. These equal v4.0's counts. Reading the Text Language adds 5 reads on
the first frame the forecast appears and on a frame where the native font
changed, never on the frames counted above. The mod never queries memory
protection and never writes game memory.

Reads land in buffers the readers keep, at plain-number addresses, and fields
and pointers decode in place. A refresh refills tables that are kept as well:
- The constellation draw keeps the game's 64-bit generator state as its two
  32-bit words in plain numbers, every partial product exact in a double, and
  fills reused tag lists. `tests/test_resolve.lua` checks the state word for
  word against `uint64_t` arithmetic and the draws against the replica it
  replaced.
- A sample keeps its spawn-weight and war-effect tables and refills them.
- The installer keeps a copy of the roster's last inputs, so an unchanged
  refresh gets its report without the roster building its cache key again.
  The display model is reused the same way.

- The native font, its material and its atlas are read every frame (4 of the
  16 reads of a steady war-table frame), so a font that is not ready hides the
  panel on that frame; their hex IDs are formatted only when the words change,
  and the status line is built only when its inputs change. The test pins zero
  `string.format` calls on a steady frame.

No frame allocates, refreshes included; the test pins that for every scenario,
interpreted and compiled, in the workspace LuaJIT and the game's `lua51.dll`.
The refresh path runs interpreted (`jit.off`): the resolver, the roster, the
mission reader's sample and the installer's refresh helpers. Its loops add no
traces to the game's shared LuaJIT code cache, and the test checks that no
trace starts in the resolver, the roster or those helpers; the per-frame
checks compile. Windows functions are declared under private names
(`hd2kyc_*`), so another mod's declarations of the same functions cannot
change how the reader calls them.

`tests/test_panel_budget.lua` runs the real panel through a fake engine that
allocates nothing and pins the panel's engine calls per frame:
- While the panel is up, every frame makes three: `Application.main_world`,
  `Application.worlds` and `Gui.resolution`. They stay per frame because each
  catches a change the panel answers on that frame: a UI world that was
  replaced or removed moves or hides the panel before it touches the GUI
  again, and a new window size lays it out again.
- A moving headline adds one `Gui.update_text`, with two
  `IdString64.from_hex`, one `Vector3` and one `Color`: engine IDs and vectors
  are temporary, so they are rebuilt each frame.
- Hidden frames make none. The frame that hides the panel lists the worlds
  once and destroys its GUI; a frame that clears or rebuilds the panel inside
  its world check reuses that check's list instead of listing the worlds again.

Hidden frames empty the panel's tables in place and waiting frames reuse one
pending model, so the panel allocates nothing on any frame either. The cost
and garbage of the engine calls themselves are unmeasured in game.

## Update chain

`install.lua` installs the vendored Bingus Shared Runtime guard (`src/bingus_runtime.lua`,
byte-identical, hash pinned by `scripts/module.py`). The forecast's frame runs in the guard's
`after`, after the previous update. The guard keeps the policy: previous update outside `pcall`,
8 errors per burst (own errors and errors below counted apart, reset after 3600 clean frames),
pause with the panel removed and resume after 60 clean frames, first failure kept through shutdown.
The build is checked with `src/bingus_memory.lua`'s `verify_build`, whose module hashes are shared
by every mod for the session. `bingus_write.lua` is never vendored; the build scans every `src/*.lua`
for write APIs. `tests/test_update_chain.lua` covers each rule.

Waiting is not an error. The readers and the panel raise expected transient
states as constant tables (`{pending = reason, status = 'hidden: ' ..
reason}`), so a waiting frame builds no string; the installer hides the
forecast, starts the selection afresh, reports the reason and tries again on
the next frame, as v4.0 did for every raised frame, and never counts the frame
toward a stop. They are: game memory that cannot be read (`Mission data
unavailable`, `Presentation data unavailable`), a record pointer that is not
set yet (`Mission pointer unavailable`, `Presentation owner unavailable`),
`Mission descriptor not ready`, `No highlighted mission`, `Briefing descriptor
unavailable`, `Briefing owner unavailable`, `Native font is not ready`, and the
panel's `UI worlds unavailable`, `Could not create forecast panel`, `Font
material unavailable`, `Font metrics unavailable`, `Font caret unavailable`,
`Retained rectangle unavailable`, `Retained text unavailable`, `Native panel
unavailable` (window below 640x480) and `Forecast exceeds viewport`. Failed
layout or bound checks (`... bound exceeded`, `Ambiguous ...`, `Unknown mission
type`, invalid tags, draws or weights), invalid text and Lua errors count.
`tests/test_pending.lua` and `tests/test_panel.lua` hold each wait for 10,000
frames.

## Compatibility

The public name is Know Your Constellation. The legacy module identifier
`mods/cowboybingus/enemy_intelligence`, global EnemyIntelligence guard and
manager GUID stay stable for compatibility with existing installations.

Public memory fixtures are constructed from fictional address ranges and
synthetic packets. Static offsets, resource hashes and regression semantics
are retained without publishing session data or personal identifiers.
