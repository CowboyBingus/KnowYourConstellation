# Static rows variant

Know Your Constellation Rows shows the same mission forecast in static rows.
Each constellation retains its bracketed name followed by its associated
units. Heavy enemies have a separate row. All rows appear together without
scrolling, pagination, section numbers or an end report marker.

Long lists wrap within the native panel width. The panel grows beneath the
left operation, planet or briefing frame, using the same font, colors and
translucent inset border. If there is too little space below, text can shrink
from size 20 to 14 before the panel moves beside the native frame. The side
placement supports size 12 for exceptionally large reports. These sizes scale
with the native UI. Text is never truncated to force a fit.

Mission resolution and visibility are shared with the scrolling release.
Pending mission data clears the rows while retaining the frame and captions.
Unhover, pod entry and loadout hide the whole panel immediately. Stable frames
reuse retained drawing objects and cached text measurements.

Install `Know-Your-Constellation-Rows-v1.zip` with Bingus Shared Loader v12 or
newer. Disable the standalone scrolling version before enabling Rows. With
Vanilla Plus Megapack, give Rows priority over the bundled forecast. The
packages have separate manager entries but share one runtime module, so only
the winning presentation loads. The original scrolling download is unchanged.

Build with `python scripts/build.py --rows`. Outputs go into `build/rows` and
the release directory. The build runs the shared tests, checks all 30 catalogue
entries and heavy enemies across six resolutions, and exercises the real rows
renderer with the installer through pending, briefing, loadout and client
unhover transitions. It also recompiles the scrolling source and verifies that
it still matches the tested v3.12 payload exactly.

The alternate layout passed offline tests and user verification in-game.
Both release variants enforce the hashes of their verified compiled payloads.
