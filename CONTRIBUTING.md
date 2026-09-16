# Building and verification

Use Python 3 and the non-GC64 Windows x64 LuaJIT commit in dependencies.json.
Set HD2_LUAJIT to that compiler. Set HD2_GAME_ROOT if the game is not in the
standard Steam installation directory.

Run `python scripts/build.py`. The build verifies the supported game hashes,
runs six offline suites, compiles stripped bytecode, verifies the runtime
against the tested v3.12 hash, and creates the release ZIP.
Run `python scripts/privacy_audit.py --zip releases/Know-Your-Constellation-v3.12.zip`.
Nested workspace projects may share their parent's releases directory.

Use synthetic fixtures in public tests. Do not commit memory captures,
session packets, screenshots, local paths, extracted game files or logs.
Keep publication-files.json synchronized with the intended public files.
Run the privacy audit with `--git` after staging to include index and history.
