# PLAYTEST2_pressure progress (branch fix/playtest2-pressure)

## Baseline (pre-change), from docs/playtests/L2_20261008-165004.json (L2 The Crown Marches)
- Lost at 351 s, node killed by creeper. First structure lost at **22.1 s** (collector, dry, unfinished).
- 37 structures lost: 30 dry ("other"), 7 wet (creeper). No `by` field existed — added now.
- Raiders alive: 6 @0:20, 28 @1:00, 35 @1:40, 44 at end. Pressure only 0.27 at loss.
- Player built 21 collectors, 5 reactors, 2 beams, **1 sniper**; 215 s on foot, 86 s starved.

## Changes so far (logic, for metrics Task 1)
- `structure.gd`: new `var last_hit_by := ""`.
- `structure_manager.gd`: prey dicts carry `"struct": s`; `damage(s, amount, source := "")` stamps it;
  `remove()` emits `"by"` in `structure_lost` (falls back to creeper/unknown).
- Stamped killers: raider melee = tier name (raiders.gd); raider shots = "spitter_shot"/"lancer_shot"
  (raider_shots.gd, threaded through _launch->_impact); trebuchet = "engine"; sentinel = "sentinel";
  creeper contact = "creeper" (structure_upkeep.gd); flyer bite = "flyer_<type>"; enemy lancer = "enemy_lancer";
  blight = "blight"; hive spitter = "hive_spitter"; spore volley = "spore_volley".
- `metrics_summary.gd`: summary now includes `lost_by` breakdown dict.
- NOTE (suggestion): `enemy_mortar_hit.gd` detonate() computes MORTAR_STRUCT damage but never applies it
  to structures — enemy mortars currently cannot hurt structures at all. Left as-is (out of brief).

## Sim tooling (Task 2)
- `--seed=N` in debug.gd (seeds global RNG before flow begins).
- `--snipe3`: lean economy instantly + 3 snipers by the Node at t=180 (brief's defence scenario).
- `--raidprobe`: [probe] lines every 5 s (raiders, marching, min dist to Node, per-nest spawned);
  first_contact (marching raider within 30 cells of Node) added to [sim] report.
- `hive_spawning.gd`: cumulative `spawned` counter per nest (debug only).

## KEY FINDING (2026-10-08): the early killer is TREBUCHETS, not raiders
- Seeded L2 sim (seed 7, --demo, 8 s): `structure_lost` event = `{'by': 'engine', 'type': 'sniper', 't': 6.1}` — the new `by` field works.
- **Ashgate's** SE corner post (40,138) is 32 cells from the base; **Thornwall's** SW post (122,155) is 32.4 cells — both inside the 40-cell ENGINE range. (First blamed Thornwall alone; a runtime trace showed the killer at world (79,275) = cell (39,137) = Ashgate's post.)
- The playtest's "30 lost to other" were largely trebuchet kills, not raiders. Raider marching=0 until raid_delay anyway.
- This also explains early collector deaths in snipe3 layout tests (they were in engine range, not on wet ground).

## Tuning APPLIED (data only)
- `level02.gd`: **Ashgate** and **Thornwall** rows gain `"engine_range": 12.0` (40.0 default → 12: trebuchets stay castle defence, can no longer shell the start base; closest base structures are 32+ cells from their posts). Other 3 castles keep 40.
- `level02.gd`: RAID_SCHEDULE `raid_delay` stays **180.0** (tried 120.0: 12 Skitters arrived t=130 and killed the node at t=183 before the t=180 snipers came online; "nothing hostile before ~2:00" is a lower bound, and 180 gives the grace period Gregory asked for plus lets the 3-sniper defence come online first).
- `level02.gd`: CASTLE_RULES `reprisal_warn` 60.0 → **120.0** (reprisal no longer lands while the Operative is still taking the first castle).
- `castle_defs.gd`: ENGINE `hp` 140.0 → **55.0** (Pulse Rifle 7.14 dps → ~7.7 s TTK ≤ 8 s; one Demo Charge (120) one-shots).
- `config.gd`: NEST_* untouched (global; L1 must stay ±15%).
- Sim tooling: `--sim` now writes the metrics file at the end of the fast-forward (so surviving runs produce metrics).

## Baseline sims (seeded)
- [x] L2 --demo 60 s (seed 7): **0 structures lost** (was 8 engine kills). Trebuchet fix verified.
- [x] L2 snipe3 360 s (seed 7, raid_delay=180): **node survived 360 s** (held until 6:00 ✓). First contact ~t=190 (after 2:00 ✓). 8 structures lost, all `by: spitter_shot` (Spitters out-trade snipers at equal 20 range). Raiders at t=300: 40 (14 marching, 26 guards) — over the <15 aim.
- [x] L2 snipe3 with raid_delay=120 (reverted): node died t=183 (12 Skitters arrived t=130, before t=180 snipers). Confirmed 180 is correct.
- [ ] L1 undefended 360 s (RUNNING, seed 7)
