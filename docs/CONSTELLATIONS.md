# Know Your Constellation - composition reference

Based on the game tables extracted on 16 September 2026 from Steam build 24826606, executable 1.8.45317.0. The extraction contains 30 named non-none tags, 177 unit-definition rows, 460 group rows and 63 replacement rules.

A base constellation selects a composition. Modifiers can add units or replace units within that composition. The tables list characteristic associations and replacement results, rather than an exhaustive final mission roster. Shared units, difficulty, mission scripts, objectives and additional modifiers still apply. Spawns are not guaranteed.

Readable constellation names match the mod. Internal tags identify the exact game entries. Community aliases such as Hive Guard Hell and Jumping Bugs are inferred equivalents, not native names. Unconfirmed unit names are retained as descriptive asset names.

## Terminids

| Constellation | Kind and native tag | Potential composition | Native rules and limits |
| --- | --- | --- | --- |
| Bile Bugs | Base, `BugAcid` | Bile Spewers and their tier-2 form, Spitters, Bile/acid Warriors, Warrior and Commander groups | Scavenger resources become Spitters from D2. The tier-2 Warrior resource becomes an acid Warrior from D3. Bile Titans and Acid Chargers are shared entries, not exclusive to this constellation. |
| Armored Bugs / Hive Guard Hell | Base, `BugArmored` | Hive Guard / `warrior_plus` entries, Warriors, Scavengers, Chargers, tier-2 Chargers and Acid Chargers | Explicit armored-unit and Charger-group associations. No tag-specific replacement rule. |
| Hunter Swarms / Jumping Bugs | Base, `BugPredators` | Hunters and Pouncers | Scavenger resources become the predator/Pouncer variant from D2. |
| Light Bugs | Base, `BugFodder` | Scavengers, Warriors, Hive Guard / `warrior_plus` entries, Brood Commander-type units and their higher-tier form | Associated light and Commander groups. No exclusive unit resource or replacement rule. |
| Bug Nursery | Base, `BugCrawlers` | Nursing Spewers, Scavengers, Warriors, Hive Guard / `warrior_plus` entries and Commander-type units | Nursing Spewers also have an untagged definition, so they are not proven exclusive to this constellation. |
| Mixed Terminids | Base, `BugBalanced` | Hunters, Warriors, Hive Guard / `warrior_plus` entries and Commander-type units, alongside eligible shared forces | Two explicitly tagged groups. No exclusive unit or replacement rule. |
| Super Predators | Modifier, `GM_BugSuperPredators` | Tier-3 Hunters, Scavenger groups and one unresolved special resource | Ordinary Hunter resources become tier-3 Hunters from D2. The extra unnamed resource is not assigned a guessed display name. |
| Gloom Variants | Modifier, `GM_BugGloom` | Gloom Scavengers, Gloom Warriors, Gloom Hunters and Gloom Bile Titans | Covered light units are replaced from D2. The ordinary Titan-to-Gloom-Titan replacement begins at D5, subject to group eligibility. |
| Burrowers | Modifier, `GM_BugBurrowers` | Burrowing Warrior, Spewer and Charger variants | Covered Warrior, Charger, Nursing Spewer and Bile Spewer resources are replaced from D6. These are the Rupture-style variants described in official enemy material. |
| Dragonroach Activity | Modifier, `GM_BugDragon_Traveler` | Dragonroaches and the Charger replacement entry | Enables the dragon resource and tagged groups. Decoded dragon groups begin at D5. Separately replaces the ordinary Bile Titan resource with a Charger from D2 in this path. Other replacement priorities can affect the outcome. |

The six base constellations above are weighted candidates at D2-D10. D1 has no random Terminid base candidate in the captured settings. This does not mean an empty enemy roster.

Bile Titans, Chargers, Acid Chargers, Impalers and other units also have definitions without a constellation requirement. A shared definition alone does not authorize a spawn in every mission. For example, ordinary Titan groups in the mod's decoded heavy-forecast pools start at D6, but objective-specific or scripted spawn paths can differ.

## Automatons

| Constellation | Kind and native tag | Potential composition | Native rules and limits |
| --- | --- | --- | --- |
| Assault Forces | Base, `BotAssault` | Melee and jump-melee infantry, Berserkers, assault lieutenants, standard/heavy/rocket soldiers and assault walkers | Covered heavy-cannon, autocannon and rocket tank resources become the assault walker from D6. Two associated infantry resource names remain unresolved. |
| Phalanx Forces | Base, `BotPhalanx` | Regular and melee infantry, commanders, standard/heavy/rocket soldiers and suppressor lieutenants | Explicit heavy-weapon and suppressor associations. No replacement rule. Some associated infantry names remain unresolved. |
| Artillery Forces | Base, `BotArtillery` | Rocket soldiers, other soldier variants, infantry, commanders, suppressor lieutenants and assault walkers | Covered tank variants become the assault walker from D6. The label is not evidence that every artillery unit must spawn. |
| Armored Column | Base, `BotPanzer` | Scout walkers, heavy-cannon/autocannon/rocket tanks, spawner walkers and supporting infantry | Explicit walker and tank group associations. No tag-specific replacement rule. Several associated resources remain unnamed. |
| Mixed Automatons | Base, `BotBalanced` | Eligible shared Automaton infantry, soldiers, lieutenants, walkers and tanks | Selectable base tag with no exclusive unit, group or replacement records. |
| Jump Assault | Modifier, `GM_BotAssault` | Jump infantry, jump-melee infantry, jump commanders, jump-pack soldiers, modified lieutenant variants and assault walkers | Replaces covered infantry and soldier resources from D1. Covered tanks become assault walkers from D6. Several replacement targets remain unnamed. |
| Cyborg Forces | Modifier, `GM_BotCyborgs` | Cyborg elite and rusher variants, including female variants, siege engines and supporting Automaton infantry/soldiers | Scout-walker resources are replaced by Cyborg elites. An additional walker resource becomes a rusher. Spawner and jammer-spawner walkers become siege engines from D7. |
| Ivory Legion | Modifier, `GM_IvoryLegion` | Ivory infantry, flamers, standard/heavy/rocket/shotgun soldiers and Ivory lieutenant variants | Replaces covered infantry, soldiers and lieutenants. Melee infantry become flamers, and Berserkers become shotgun soldiers. Several variant resource names remain unresolved. |

The five Automaton base constellations are weighted candidates at D2-D10. D1 has no random Automaton base candidate in these settings. Gunships and other units also have untagged definitions, with their actual use controlled by additional conditions.

## Illuminate

| Constellation | Kind and native tag | Potential composition | Native rules and limits |
| --- | --- | --- | --- |
| Illuminate Invasion | Default, `GM_IlluminateInvasion` | Corrupted variants, staff units, jet champions, beam champions, observers, tripods, `meatglue` units and attack ships | Fallback composition when Engineers, Invasion, Harvest and Body Horror are all absent. These are native asset descriptions, not newly assigned official unit names. |
| Illuminate Engineers | Modifier, `GM_IlluminateEngineers` | Staff units, jet champions, observers, tripods, melee/ranged exomechs and two unnamed resources | The beam-champion resource becomes a jet champion. |
| Illuminate Harvest | Modifier, `GM_IlluminateHarvest` | Corrupted variants, staff units, beam champions, observers, tripods and `meatglue` units | Jet champion has a priority-2 replacement to beam champion from D1 and a priority-1 replacement to `meatglue` from D5. When both rules apply directly, the higher-priority beam rule wins. These are not two guaranteed replacements. |
| Body Horror | Modifier, `GM_IlluminateBodyHorror` | Corrupted variants, `meatglue`, `bodyhorror_helmetguy` and `bodyhorror_bladed` | Direct unit and group associations. No replacement rule was found for this tag. |

No weighted random Illuminate base candidates appear at D1-D10 in these settings. Invasion is a fallback rather than a random base draw. Corrupted, observer and tripod are internal family descriptions corresponding broadly to the Voteless, Watcher and Harvester roles. Exact unresolved variants retain their asset labels.

## Tags present but composition unresolved

| Faction | Mod label and native tag | What the extraction establishes |
| --- | --- | --- |
| Terminids | Flyer Composition, `BugFlyers` | Tag exists, but it is absent from the random base candidates and has no direct unit/group/replacement association here. It is not evidence of Dragonroach activity. |
| Terminids | Shrieker Modifier, `GM_BugShrieker_Traveler` | Tag exists, but its activation-to-unit mapping is unresolved. A separate ordinary Shrieker resource exists. |
| Terminids | Hive Lord Modifier, `GM_BugHiveLord` | Tag exists, but its activation-to-unit mapping is unresolved. A separate Hive Lord resource exists. |
| Automatons | Air Composition, `BotAir` | Tag exists, but it is absent from the random base candidates and has no direct association here. |
| Automatons | Gunship Modifier, `GM_BotGunships_Traveler` | Tag exists, but its activation-to-unit mapping is unresolved. Gunships have a separate untagged definition. |
| Illuminate | Illuminate Stragglers, `IlluminateStraggler` | Tag exists without a direct association here. It is not the captured build's default Illuminate composition. |
| Illuminate | War Machine Modifier, `GM_IlluminateWarmachine_Traveler` | Tag exists, but its activation-to-unit mapping is unresolved. A separate Illuminate war-machine definition exists. |

An unresolved association is not proof that the tag is unused by every game system.

## Shared friendly-force modifier

| Entry | Native tag | Potential composition |
| --- | --- | --- |
| SEAF Support | `GM_SEAF` | SEAF soldier, leader, specialist and medic variants. This is a friendly-force modifier, not an enemy constellation. |

## Evidence and scope

- Composition associations come from the extracted unit, group and replacement tables, not from the short marquee descriptions or community frequency claims.
- The game.dll SHA-256 is `CC75948D90FDFDE259DCB519E9933DB7FFA3CCB281CE4FB89E6B1B011557470C`.
- Some asset names are unresolved. The table does not invent display names for those resources.
- Replacement sources are not treated as guaranteed members of the resulting roster. Multiple modifiers can compete or chain.
- No universal "spawns more" or "spawns less" ranking is asserted. Those require the relevant group weights, mission conditions and difficulty.
- Coverage is complete for the 30 named tags in this extraction. It is not a claim that all spawn systems, objective scripts or the undecoded table sections have been reconstructed.

Official naming cross-check: the [PlayStation enemy guide](https://www.playstation.com/en-us/games/helldivers-2/#know-your-enemy) documents Dragonroach, Rupture Charger, Rupture Warrior, Rupture Spewer, Voteless, Watcher and Harvester. It does not document the internal constellation-to-resource relationships. The descriptive asset-to-role correspondences above are interpretations of the local data.
