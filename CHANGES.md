# CHANGES.md: behaviour changes waiting for Gregory's ruling

Anything here changes (or already changed) behaviour that was working and that Gregory did not ask to change. Nothing in "Proposed" is built until he marks it. Mark each entry **KEEP**, **REVERT**, or **APPROVE** / **REJECT**, or just tell Claude the number.

## Already in the build without being asked (merged 2026-10-10 with the performance branches)

| # | What changed | Before | Now | Why it was done | Ruling |
|---|---|---|---|---|---|
| 1 | Raiders and castle guards choosing a target | Re-checked every frame | Re-checked every 0.3-0.5 s | Speed | **Gone (2026-10-10).** Replaced by the commit-to-a-target fix you asked for: a raider with a target no longer re-checks on a timer |
| 2 | Spitters and Lancers choosing a target | Every frame | Every 0.3-0.5 s, last pick kept while in range | Speed | **Gone (2026-10-10).** Shooters now keep their pick until it dies, leaves range or (Lancers) sight; no timer |
| 3 | Enemy mortars aiming | Every frame | Every 0.3 s; the "can raiders walk to the Node" test every 0.25 s | Speed | |
| 4 | Hive bookkeeping (stage unlocks, health caps, mortar count) | Every frame | Every 0.25 s | Speed | |
| 5 | Nests checking whether a spawn is due | Every frame | Every 0.25 s (spawn timing itself unchanged, at most 0.25 s late) | Speed | |
| 6 | "Raiders are in this castle zone" test (used for retakes and stage changes) | Every frame | Every 0.2 s | Speed | |
| 7 | Flyers' height over the ground | Re-measured every frame | Re-measured after moving 0.75 m | Speed | |
| 8 | Raider group speed | Slowest living member | Slowest member, dead ones included until they are removed | Side effect of a cache (a bug) | **Fixed (2026-10-10).** Dead raiders are skipped again |
| 9 | Enemy builder choosing a build site | Whole search in one frame (caused the 1 s freezes) | Search spread over several frames, same site chosen | Speed (fixes the freeze) | |
| 10 | Your units getting a path when ordered as a group | Every unit pathed the same frame (caused 0.2-0.9 s freezes) | Up to 3 ms of path searches per frame; the rest wait a few frames | Speed (fixes the freeze) | |
| 11 | A unit's destination that cannot be reached | Searched again every time | Not searched again for 3 s | Speed | |
| 12 | Unit path search limit | No cap | Gives up after 6000 cells and walks to the closest point found | Speed | |
| 13 | Salvage Engines tied to a castle | Shipped only while you held that castle | Ship once hooked | Claude's reading of "no condition other than hooking it up" | |
| 14 | Test: "dry unit retreats past enemies" | Unit also had to survive | Only has to retreat without engaging | It failed at random | |
| 15 | Test: "a safe engine is near the landing site" | An engine with no hive/castle tie within 40 cells | Any engine within 40 cells | The hive/castle ties were removed | |

## Proposed (not built)

| # | What would change | Today | Proposed | Why | Ruling |
|---|---|---|---|---|---|
| P1 | Your units chasing a moving enemy on an attack order | The unit works out a new path to the enemy once a second | Walk straight at it when the way is clear; work out a new path only when the enemy has moved about 4 cells from where the old path ended | Same "lock on, don't keep recalculating" rule you gave for enemies, applied to your own units. You did not ask for this one; units behave as they did until you approve it | |
| P2 | Firing Range movement inertia | Ground movement snaps instantly to your input (removed 2026-10-14 at your request); weight only slows changes in the air | Ground acceleration returns, scaled by what you carry: light loadout feels near-instant, a full backpack and long gun ramp up and slow down noticeably | You said inertia is OK "when it's balanced"; the Tarkov inventory (RANGE2) makes weight real. Numbers would be tuned with you | |
| P3 | Firing Range / Skirmish gun recoil | One kick value moves camera and aim together, jumps instantly per shot, random side jitter each shot, decays to centre | Tarkov-style: spring kick (fast rise, damped return), bullets follow the barrel while the camera follows ~15-50 % of it, per-gun convergence so full auto plateaus, per-gun recoil angle + smooth drift (learnable pattern), strong visual gun kick | You said recoil "didn't feel great"; research in `docs/research/RECOIL_TARKOV.md`. Built as an Esc-menu toggle (Classic default) so you can A/B it; the default switches only when you rule here || **APPROVED 2026-10-14** ("sounds like it's time to start that"); spec: TRP docs/spec/weapon-handling.md |
| P4 | Where ADS puts the gun (every gun) | Gun pushed forward by `half_len - butt`, so the stock ends at or behind the eye (M4A1: eye 3 cm behind the butt) and the 0.25 m near plane hides it | Eye ~0.30 m forward of the butt plate (cheek weld, butt in the shoulder pocket); the near plane can drop so the stock is visible as in a real sight picture | F28: the butt goes "down his throat", and hand-posed arms can't sit right in ADS || **APPROVED 2026-10-14** ("sounds like it's time to start that"); spec: TRP docs/spec/weapon-handling.md |
| P6 | ADS alignment and the viewmodel near plane (every gun) | Per-gun `ads_pos` heights/x offsets and `eye`; no ADS rotation, so canted or pitched models stay canted; camera near plane lerps per sight (F50 broke the M1911) | One rule (FB-H): rear + front sight on the screen-centre axis, bore straight below, rear sight at a per-class eye relief. Viewmodel materials use Godot's z-clip scale (own near plane, gun never draws through walls); camera near fixed. M1911 follows the rule. P90 gets the red dot by default. New iron sights modelled for m4a1, mp5, vector, sr25, pkm | Gregory: align every gun by one rule; option A chosen | **APPROVED 2026-10-15** (option A, rulings in chat) |
| P5 | Hand-posed M4A1 arms at ADS | One pose fixed to the gun at hip and ADS alike (left sleeve end shows in ADS; right hand rises beside the rear sight) | Two poses posed by Gregory (hip and ADS), blended by the ADS amount; other guns unchanged | Follows P4; a single pose can't be right in both | |
