# v4.1

- New: Simplified Chinese translation by joyrhyme (pull request #3); it shows when the game's Text Language is Simplified Chinese.
- Fixed: Hive Worlds list Hive Lords again, and other planet campaign modifiers such as Dragonroach activity apply again. On game build 25480438 the forecast read a stale offset that switched every one of them off.
- Every Windows function the mod calls is declared under a private name, so another mod that declared the same functions first can no longer keep the forecast from starting.
- With a game language other than English, a shared translation table left incomplete by another mod no longer keeps the forecast hidden.
- A translation pack forces its language on every mod only when it sets `force = true`.
- With the war table or briefing open, the forecast no longer creates garbage every frame: 3-7 KB per frame before (measured in game), none now (measured in the game's Lua runtime outside the game).
- The 0.5 s refresh of a highlighted mission no longer creates garbage: 232 bytes per refresh before, 824 with spawn weights (measured in the game's Lua runtime outside the game).
- On the ship and in missions, where the forecast is hidden, it no longer creates 128 bytes of garbage every frame (measured in the game's Lua runtime outside the game).
- While the forecast waits for mission data with its panel up, it reuses one pending panel instead of making a new one every frame.
- With the panel up, the font's resource IDs and the status line are rebuilt only when they change. The font is still checked every frame, so an unloaded font hides the panel at once.
- Less of the mod's code is compiled into the game's shared LuaJIT code cache: about 49 KB instead of 59 KB in an offline play-like run.
- The update runs on Bingus Shared Runtime's guard, the error policy the family's mods share, and the game build check uses the runtime's module hashes, read once per session for every mod.
- After 8 errors in one burst the forecast removes its panel and stops for the session instead of retrying every frame. Errors about a minute (3600 frames) apart never add up, and each burst logs only its first error.
- When the game's update or another mod's raises an error, the forecast removes its panel and pauses until 60 frames pass without one; 8 of them in a burst stop it.
- Waiting while the game builds its menus or switches screens is not an error: the forecast hides and tries again on the next frame, however long it lasts.
- The shutdown status keeps the first failure (`stopped after: <reason>`); a session without one keeps its last status.
- Measured in live play: 0.007 ms per frame in missions and 0.013 on the ship.

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
