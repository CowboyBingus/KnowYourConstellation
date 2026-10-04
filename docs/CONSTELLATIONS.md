# How the forecast is built

Know Your Constellation v4.1 reads the enemy spawn tables in the game module of Steam build 25480438 (executable 1.8.46015.0) and replays their rules for the highlighted mission. Enemy names and size classes follow the [Helldivers Wiki](https://helldivers.wiki.gg).

## Inputs

- **Enemy tags.** Every mission resolves a list of tags before deployment: a base constellation chosen from the mission seed, plus subfactions, strains and operation modifiers from the campaign. The mod resolves the same list the game does; see [runtime design](TECHNICAL.md).
- **Difficulty.** Unit and group weights differ per difficulty.
- **Spawn-weight modifiers.** Campaign modifiers and war effects can scale the weight of every group containing a given enemy family. They are applied when the game reports them for the hovered planet.

## Where enemies come from

Each faction has one table of unit rows, groups and replacement rules. Groups sit in pools, each used by a different spawner:

| Pool | Used for | In the forecast |
| --- | --- | --- |
| Patrols | Roaming patrols; each patrol type (default, horde, harvest, observer) runs on its own timer | Listed and weighted |
| Reinforcements | Bug breaches, bot drops, Illuminate warp-ins | Listed and weighted |
| Garrisons | Groups guarding outposts and points of interest | Listed and weighted |
| Border travellers | Flyers crossing the map: roving Shriekers, Gunship patrols, Leviathans, Dragonroaches | Only when the mission carries the matching modifier |
| Air support | Illuminate Stingrays | Invasion Fleet only |
| Convoys, stragglers | Objective convoys; special modes | Not forecast |

A group is possible when its difficulty range, player range and required tags match and its weight is above zero. Every member of the group needs at least one possible unit, otherwise the whole group is dropped. Each unit then passes through the replacement rules: the highest-priority matching rule wins, and chained replacements may not lower the priority.

Commanders' summons are listed with them: Brood Commanders call Warriors, and Alpha Commanders call Alpha Warriors.

## The spawn-rate meter

Large and massive enemies (wiki size classes) get a ten-bar meter; small and medium enemies are listed most common first.

The meter shows each enemy's share of spawned enemies, averaged over patrols, reinforcements and garrisons. Ten bars means about one enemy in six; every 1.5 bars fewer halves the share; one bar marks a rare enemy. Border travellers count as one more patrol stream, and Illuminate air support as a quarter of one, because its timer is three to four times longer.

## What each tag changes

Numbers in brackets are the difficulty from which a rule applies (1 Trivial ... 10 Super Helldive).

### Terminids

| Shown as | Native tag | Effect |
| --- | --- | --- |
| Bile Bugs | `BugAcid` | Bile Spewer groups; Scavengers become Bile Spitters; Warriors become Bile Warriors |
| Armored Bugs | `BugArmored` | More Hive Guard and Charger groups |
| Hunter Swarms | `BugPredators` | More Hunter groups; Scavengers become Pouncers |
| Light Bugs | `BugFodder` | More Warrior and Brood or Alpha Commander groups |
| Bug Nursery | `BugCrawlers` | Nursing Spewer groups |
| Balanced Terminids | `BugBalanced` | Mixed Hunter, Warrior and Commander groups |
| Predator Strain | `GM_BugSuperPredators` | Hunters become Predator Hunters; Predator Stalkers (4) |
| Spore Burst Strain | `GM_BugGloom` | Scavengers, Warriors and Hunters become Spore Burst variants; Bile Titans become Spore Burst Bile Titans (5) |
| Rupture Strain | `GM_BugBurrowers` | Warriors, Nursing Spewers, Chargers and some Bile Spewers become Rupture variants (6) |
| Dragonroach Activity | `GM_BugDragon_Traveler` | Dragonroaches (5); Bile Titans become Chargers, except under the Spore Burst Strain |
| Roving Shriekers | `GM_BugShrieker_Traveler` | Shrieker patrols (inferred from the tag name and the wiki's operation modifier) |
| Hive World | `GM_BugHiveLord` | Hive Lord (7) |
| Horde | `HordeOnly` | Extra Bile Titan, Charger, Impaler and Shrieker groups |

Brood Commanders become Alpha Commanders from 8, and Chargers share their slots with Charger Behemoths and Spore Chargers from 7.

### Automatons

| Shown as | Native tag | Effect |
| --- | --- | --- |
| Assault Forces | `BotAssault` | Assault Raider, Brawler and Berserker groups; tanks become War Striders (6) |
| Phalanx Forces | `BotPhalanx` | More MG Raiders and Heavy Devastators |
| Artillery Forces | `BotArtillery` | More Rocket Raiders and Rocket Devastators; tanks become War Striders (6) |
| Armored Column | `BotPanzer` | Scout Strider and tank groups |
| Balanced Automatons | `BotBalanced` | Mixed groups |
| Jet Brigade | `GM_BotAssault` | Troopers (from 3), Marauders, MG Raiders, Commissars, Devastators and Hulks become Jet Brigade variants; Brawlers become Assault Raiders; tanks become War Striders (6) |
| Incineration Corps | `GM_IvoryLegion` | Brawlers become Pyro Troopers, Berserkers become Conflagration Devastators, Heavy Devastators become Incendiary MG Devastators, Rocket Raiders become Incendiary Rocket Raiders, Hulk Bruisers become Hulk Firebombers |
| Cyborg Legion | `GM_BotCyborgs` | Scout Striders become Agitators and Reinforced Scout Striders become Radicals; Factory Striders become Vox Engines (7) |
| Gunship Patrols | `GM_BotGunships_Traveler` | Gunship patrols (inferred from the tag name and the wiki's operation modifier) |

War Striders never appear together with tanks: wherever they exist, every tank slot has become a War Strider.

### Illuminate

| Shown as | Native tag | Effect |
| --- | --- | --- |
| Invasion Fleet | `GM_IlluminateInvasion` | Voteless, Overseers of every kind, Watchers, Harvesters, Fleshmobs and Stingrays |
| Appropriators | `GM_IlluminateEngineers` | Veracitors, Gatekeepers and Obtruders; no Voteless or Fleshmobs; Crescent Overseers become Elevated Overseers |
| Mindless Masses | `GM_IlluminateHarvest` | Voteless and Fleshmob hordes; Elevated Overseers become Crescent Overseers |
| Vote Snatchers | `GM_IlluminateBodyHorror` | Only Wretches, Crushers, Voteless and Fleshmobs |
| Leviathan Blockade | `GM_IlluminateWarmachine_Traveler` | Leviathans (inferred from the tag name and the wiki's operation modifier) |

`SEAF Support` (`GM_SEAF`) adds friendly SEAF squads and is shown in the headline only.

## Not forecast

- Enemies from map features: Stalker lairs, Shrieker nests, Gunship facilities, fabricators and other spawners.
- Objective-specific enemies, such as Eliminate targets, convoy Factory Striders and captive bugs.
- Mission-type exclusions that live outside the spawn tables. The wiki reports, for example, that War Striders skip some mission types outside Metropolis biomes.

Two garrison groups that this build raised from weight 0 to 0.01 (Nursing Spewers and an unidentified Charger variant) are treated as disabled; the wiki does not report those enemies there.

Spawns are never guaranteed: the forecast lists what the mission's rules allow and how they weight it, not what will appear.
