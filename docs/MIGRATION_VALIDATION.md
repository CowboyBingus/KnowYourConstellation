Supports Helldivers 2 Steam build 25480438 / EXE 1.8.46015.0.

v4.0 status: offline source, package and read-only checks passed. In live play
(2026-09-30, the release candidate inside Vanilla Plus Megapack v36, same compiled
bytes) it loaded, read the game's Text Language and drew its forecast on the war
table, at about 0.05 ms per frame while shown and 0.007 ms otherwise. An earlier
v4.0 test build confirmed that the box draws above the planet panel and the
squad list. Not yet checked in game: the briefing placement and lobbies of two
to four players.

Offline coverage:
- The spawn data was decoded from this build's game module. Its eligibility
  rules reproduce the Helldivers wiki's subfaction descriptions for all three
  factions (for example, Vote Snatchers field only Wretches, Crushers, Voteless
  and Fleshmobs; Berserkers are absent under the Incineration Corps; Dragonroach
  missions replace Bile Titans with Chargers except under the Spore Burst Strain).
- The renderer is tested at six resolutions with short and long planet
  panels: every enemy is named at full or reduced text size, the box stays
  between the planet panel and the prompt row on layers 990 and above, and
  unchanged reports make no GUI calls.
- Per-frame game reads were counted for the ship, war table, briefing and
  loadout. They equal v3.16.1's counts in every state.

The v3.16 runtime loaded in live play and ran its forecast while the galactic
map was open, costing about 0.1 ms per frame there and under 0.01 ms per frame
aboard the ship and in missions.

Public source excludes raw memory captures and private session recordings.
Install with the game closed, then Purge / Deploy in one mod manager.
Use Bingus Shared Loader v18.
