# Building and verification

Use Python 3 and the non-GC64 Windows x64 LuaJIT commit in dependencies.json.
Set HD2_LUAJIT to that compiler. Set HD2_GAME_ROOT if the game is not in the
standard Steam installation directory.

Run `python scripts/build.py`. The build verifies the supported game hashes,
runs the offline suites (including the per-frame budgets in
`tests/test_budget.lua` and `tests/test_panel_budget.lua` and the FFI name
clash test in both declaration orders), compiles stripped bytecode, verifies
the runtime against the payload confirmed in game and creates the release ZIP.
Until a new runtime has been checked in game, build a local test package with
`--allow-untested`; after the check, record the resource hash printed in
`build/build-report.json` as `TESTED_RESOURCE_SHA` in `scripts/module.py`.
Run `python scripts/privacy_audit.py --zip releases/Know-Your-Constellation-v4.1.zip`.
Nested workspace projects may share their parent's releases directory.

`src/roster_data.lua` is generated from the supported build's faction tables
and must be regenerated and re-reviewed after a game update. Keep
`tests/frame_budget.lua` byte-identical to the shared canonical copy.

Use synthetic fixtures in public tests. Do not commit memory captures,
session packets, screenshots, local paths, extracted game files or logs.
Keep publication-files.json synchronized with the intended public files.
Run the privacy audit with `--git` after staging to include index and history.
