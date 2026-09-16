# Runtime design

The module reads local mission preview data and draws a separate native GUI
strip. It does not modify the game's widgets, gameplay memory or networking.
The supported executable and game module hashes are enforced at startup.

The resolver combines the mission seed, difficulty tables, campaign and
operation modifiers, level tags and exclusion rules. Enemy catalogue entries
describe constellation members. Heavy-enemy entries describe static table
eligibility, not every spawn path or a guarantee of an encounter.

Hosted previews use the highlighted operation's planet, even if the ship's
active operation is elsewhere. Remote previews require matching advertisement
and loaded preview packets. The reader withholds incomplete or stale reports.
Briefing uses the selected mission descriptor and its matching controller.

Panel placement follows the native left operation or planet frame. Briefing
visibility follows the native tab and inherited opacity. Remote selection
activity immediately hides the entire strip after unhover. Font, material
and atlas references come from the active locale's native body font.

The public name is Know Your Constellation. The legacy module identifier
`mods/cowboybingus/enemy_intelligence`, global EnemyIntelligence guard and
manager GUID stay stable for compatibility with existing installations.
Renaming the package does not change the tested v3.12 runtime bytecode.

Public memory fixtures are constructed from fictional address ranges and
synthetic packets. Static offsets, resource hashes and regression semantics
are retained without publishing session data or personal identifiers.

Validation covers hosted and remote forecasts, cross-planet identity,
operation modifiers, pending previews, stale controllers, pod entry, loadout,
frame placement, native font mapping, marquee continuity and unhover.
The final v3.12 operation hover fix was confirmed in-game before publication.
Positive live Dragon modifier coverage and joined-session briefing coverage
remain limited. No claim of exhaustive live coverage is made.
