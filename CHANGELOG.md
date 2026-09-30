# v4.0

- Shows the exact enemies each mission can spawn, read from the game's spawn tables for its constellation, subfaction and difficulty.
- Names every unit as on the Helldivers wiki and uses the in-game subfaction and strain names.
- Adds a spawn-rate meter for every large enemy and lists smaller enemies most common first.
- Draws the forecast as one box below the planet panel, above the squad list.
- Keeps the headline on one line and scrolls it when it is wider than the box.
- Updates the spawn data for Steam build 25480438 and applies campaign and war-effect spawn modifiers.
- Replaces the scrolling and Rows packages with a single layout.
- Translatable: texts follow the game's Text Language when a translation is installed, and any script wraps by character (see TRANSLATING.md).
- Measured in live play: about 0.05 ms per frame while the forecast is shown and 0.007 ms otherwise.

# v3.16.1

- Documentation-only release: both packages are identical to v3.16 (same compiled resource).
- Rewrites the install notes packaged with both packages and the README status: one current status line instead of the compatibility-candidate and test-build notes left from the game-build update. The mod loads in live play and runs its forecast on the galactic map.
- Lists one loader requirement, Bingus Shared Loader v18.

# v3.16

- Update the relocated mission-tag table for Steam build 25480438.
- Keep both scrolling and Rows forecast layouts.
- Offline builds and package checks pass; live gameplay validation remains pending.

# v3.15

- Update compatibility for game build 25327279.
- Restore enemy forecasts on mission previews and briefing screens.
- Refresh mission rules in both scrolling and Rows layouts.

# v3.13

- Moves logs to `%LOCALAPPDATA%\CowboyBingus\Helldivers2\Logs`.
- Requires Bingus Shared Loader v14 for the shared log folder.
- Includes updated scrolling and Rows packages.
