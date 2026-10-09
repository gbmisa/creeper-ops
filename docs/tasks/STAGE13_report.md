# Stage 13 tuning audit (Task T) — report

**Method:** measure and propose; no tunables changed. Source: `main` @ `54dc89dc` (HEAD 4a23ee04 is docs-only; P `fix/playtest2-pressure` not merged, so L2 is pre-P). Godot 4.7.2-stable headless, parse clean (0 script errors).

**Deviation from brief:** the brief asks for 18 sims (3 runs × 3 configs × 2 levels, median). The shared VM runs 10+ sibling workers (load 12–18 on 2 CPUs); a 600s sim gets ~9% CPU and takes ~40 min, so 18 runs ≈ 20+ hours. I ran one validation sim (L1 `--demo --units --sim=300`) for the income number and did the rest analytically. `Pressure.value(level, t)` is a pure function of level + time, so the curve and all unlock times are exact, not sampled.

**Validation run** (L1, `--demo --units --sim=300`): time 300, over false, win −1, node_hp 500, pressure 0.00, income **4.39/s**, energy 103, salvage 58 (earned 58), ore 0, aether 25, tier Skitter, raiders 14, coverage 0.11, objectives [e1], weapons dry 0/19, unmet 0.0.

## 1. Baselines

18-run medians not collected (see above). Pressure values below are exact (time function).

| level | config | pressure @end |
|---|---|---|
| L1 | autostart 600 | 0.31 |
| L1 | demo+units 900 | 0.60 |
| L1 | demo+units 1800 | 0.92 |
| L2 | autostart 600 | 0.60 |
| L2 | demo+units 900 | 0.85 |
| L2 | demo+units 1800 | 1.00 |

The scripted demo never moves the Operative, so Spire/Deep Core objectives can't complete — no demo win is measurable; win-vs-cap can't be assessed from scripted runs (needs scripted Operative play or human timing).

## 2. Unlock table (ranged + air)

First appearances exact (pressure curve). Income 4.39/s measured.

| Enemy | L1 | L2 | Counter (cost) | Secs of income | Verdict |
|---|---|---|---|---|---|
| Spitter (10HP rng20, 6dmg/2s) | 6:30 | 4:00 | Sniper 75 (3 shots/4.5s; wins 20v20 trade) / Operative free | 17 | OK |
| Spore Bat (5HP alt6, dive 4dmg) | 9:45 | 6:15 | Beam 20 (rng 23) / Flak I 25 Salv | 5 | OK |
| Gasbag (45HP alt10, drops creeper) | 13:15 | 8:45 | Beam 20 (~7s/bag) | 5 | OK |
| Lancer (14HP rng32, 25dmg/1.5s) | 14:07 | 9:22 | Operative free (rifle 90m > 64m) / Lance 40 (99dmg, 60s cd). Sniper 20, all turrets ≤20 outranged | 9 | tight |
| Hive spitter (50HP rng20) | 14:07 | 9:22 | Sniper 75 / Lance 40 one-shots | 17 / 9 | OK |
| Spotter (8HP, sights 25m) | 17:48 | 12:00 | Sniper 75 (2 shots) / Operative | 17 | OK |
| Spore launcher (40HP, volley/60s) | 17:48 | 12:00 | Beam intercepts (SPORE_HP 3) / Lance / Operative | 5 | OK |
| Wyvern (90HP alt8, 12dps breath) | 20:36 | 14:00 | Beam 20 (~14s each) / Lance one-shots / Operative | 5 | tight |
| Enemy mortar (80HP rng36, 30dmg/6s) | 33:59 | 24:59 | Operative sabotage (3s @3m) / Lance one-shots | 9 | OK (late) |

Notes: "phase 7" comment in raider_defs.gd is stale; hive mortar is stage 4 (p≥0.95). Lance damages raiders (99 in 4.5 cells) — valid counter, not just anti-creeper.

## 3. Pressure curve

Cap: L1 40:00, L2 30:00. Win-before-cap: not measurable (see §1).

| min | 0 | 5 | 10 | 15 | 20 | 30 | 40 |
|---|---|---|---|---|---|---|---|
| L1 | 0.00 | 0.00 | 0.31 | 0.60 | 0.78 | 0.92 | 1.00 |
| L2 | 0.00 | 0.20 | 0.60 | 0.85 | 0.90 | 1.00 | 1.00 |

L1: grace 300s; points (480,0.20) (900,0.60) (1320,0.85) (2400,1.0). L2: grace 180s; points (300,0.20) (600,0.60) (900,0.85) (1800,1.0).

## 4. Salvage

Sinks: turrets I/II/III — Repeater [25,40,70], Lobber [30,45,75], Flak [25,40,70]; wall repair 1/10HP; AP/incendiary 0.4/round; cluster rockets 5/rocket; graded-ammo packets +0.5; demo charges 8.
Sources: castle capture +30, held castle +0.1/s, hive core 40, crown 15, hive parts 5, enemy mortar 5, raider loot (Operative pickup only, 90s life).

Validation run earned 58 Salvage in 5 min (demo, no looting/captures). Real-play income is higher. A win's surplus vs. the sink list: a full turret set (e.g. 3× Flak III = 135) plus graded ammo consumes hundreds — prices look calibrated for "little left over". No change proposed.

## 5. Proposals (not applied)

| # | File | Key | Old → New | Why | Serves target |
|---|---|---|---|---|---|
| 1 | godot/scripts/core/config.gd | LANCE_COOLDOWN | 60.0 → 45.0 | Lance is the only network counter for Lancer (rng 32) and enemy mortar (rng 36); Sniper (20) and all turrets (≤20) are outranged. 60s cooldown leaves a long window where a dead/out-of-position Operative means no answer. | Ranged enemy has an affordable counter |
| 2 | godot/scripts/level/flyer_defs.gd | Wyvern hp | 90.0 → 70.0 | Beam (6.7 dps) needs 13.5s per Wyvern; at 70 HP it's ~10.5s, keeping a single Beam viable without making Wyverns trivial for Operative/Lance. | Ranged enemy has an affordable counter |
