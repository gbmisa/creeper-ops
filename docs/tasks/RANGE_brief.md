# Brief RANGE: Tarkov-style combat module + Firing Range level

Worktree `creeper fps td-worktrees/range`, branch `feat/firing-range` (from `integ/2026-10-09`).
Progress log: `docs/tasks/RANGE_progress.md` (append one short block per phase: done, verified, open issues).
Read: `AGENTS.md`, this brief, the progress log, and only the files you change or call.

## Goal
Gregory wants the game to move toward few, smart, Tarkov-like fights. This stage builds a **standalone, reusable
combat module** (`godot/scripts/tactical/`) and a **Firing Range** scene that shows it off. Nothing is wired into
the main game yet.

## Must NOT change (hard rule, see CLAUDE.md)
- Any existing behaviour of the main game: no edits to files under `scripts/` outside `tactical/` and `range/`,
  **except** `scripts/core/keybinds.gd` (append new action ids + the `"Tactical"` group, nothing else).
  Never rename or rebind existing ids. Tests set `Keybinds.persist = false`. Never touch `user://keybinds.cfg`.
- `scenes/main.tscn`, `project.godot` main scene, the smoke checks. Main smoke must stay all PASS.
- You may reuse existing helpers read-only (`InputState`, `Keybinds`, `MuzzleFlash`, `Sfx`, `UiTheme`, `UiKit`).
  If one of them needs a change to work standalone, **stop and report**. Don't edit it.

## Launch and tests (all run from `godot/`)
- Play: `godot --path . res://scenes/firing_range.tscn`. Add `tools/range.sh` that runs this.
- Headless logic test: `godot --headless --path . res://scenes/firing_range.tscn -- --range-test`. It prints one
  `[range] PASS <name>` / `[range] FAIL <name>: why` per check, then `[range] OK n` or `[range] FAILED n`, then quits.
- Screenshot hook (Xvfb, like the main game): `-- --shot=/abs.png [--weapon=ak47] [--ads] [--look=x,y,z]
  [--fire=N] [--wait=s] [--bots]`, which waits, takes the shot, then quits.
- Every phase: parse clean (`godot --headless --path . --import 2>&1 | grep -A1 "SCRIPT ERROR"` is empty),
  `--range-test` OK, main smoke all PASS (`-- --smoke --quit=0.1 | grep -c FAIL` is 0). Commit each phase.

## Assets (already in repo)
`godot/assets/models/guns/{m1911,p90,ak47,shotgun,garand,sniper}.glb`. Muzzle along **-Z**, real length in
metres, origin at the bbox centre. Each has an AnimationPlayer with clips:
m1911 `Fire Reload Slide`, p90 `Fire Reload`, ak47 `Fire Reload`, shotgun/garand/sniper `FireWBullet FireWOBullet Reload`
(`FireWBullet` = fire + cycle/eject, i.e. the pump or bolt cycle; `FireWOBullet` = last round, no cycle).
Credits: `assets/models/guns/CREDITS.md`. Clip lengths are short (6-46 frames @24fps), so scale `speed_scale` to the action time.

## Code layout (keep each file under ~250 lines; class_name + static helpers; tunables in def tables)
`scripts/tactical/` is reusable for future operatives and bots, and must not depend on `range/`:
- `tactical_config.gd`: all module tuning numbers (gravity, sim step, stamina, sway, spill, bleed rates...).
- `ammo_defs.gd`, `weapon_defs.gd`, `armor_defs.gd`, `material_defs.gd`: data tables + `of(id)`.
- `ballistics.gd` (`Ballistics`): live projectiles, stepped in fixed substeps (≤ 1/240 s) with segment raycasts.
- `penetration.gd`: static rules for armor and world-material penetration and ricochet.
- `body_health.gd` (`BodyHealth`): zones, damage, blackout spill, bleeds, fractures, death.
- `hitbox_rig.gd`: builds zone colliders for a body and maps collider → (owner, zone).
- `magazine.gd`, `gun.gd` (runtime weapon state), `recoil_model.gd`.
`scripts/range/`: `firing_range.gd` (scene root, wiring only), `range_layout.gd`, `range_targets.gd`, `dummy.gd`,
`tactical_player.gd`, `player_weapons.gd`, `tactical_viewmodel.gd`, `range_hud.gd`, `range_hit_log.gd`,
`range_bench.gd`, `range_args.gd`, `range_test.gd`; phase 4 adds `kill_house.gd`, `scav_bot.gd`,
`bot_perception.gd`, `bot_brain.gd`, `bot_mesh.gd`. Split further if a file grows.

Physics layers: 1 world, 2 hitboxes (bullet-only), 3 character movement bodies. Bullets query layers 1+2 and
ignore the shooter's own hitboxes. World colliders carry `set_meta("mat", "<material id>")` and
`set_meta("thick", metres)`.

## Mechanics (Tarkov-like; numbers are starting values, tune by feel)
**Ammo** (`dmg, pen, armor_dmg, v0 m/s, drag k per m, frag, lbleed, hbleed, pellets`; damage and pen scale with v/v0):
- 45acp: FMJ 72/25/0.36/340/0.0021, AP 66/38/0.48/299, Hydra-Shok 100/13/0.15/340 frag .5
- 57x28: SS190 49/37/0.53/715/0.0016, SB193 59/27/0.4/305 (subsonic), R37.F 98/8/0.2/729 frag .6
- 762x39: PS 57/35/0.52/700/0.0012, BP 58/47/0.63/730, HP 80/15/0.2/754 frag .4
- 12ga: 7mm buck 8×39/3/0.26/415/0.006, Magnum buck 8×50/2/0.2/385, AP-20 slug 164/37/0.65/510/0.0035, Flechette 8×25/31/0.26/320
- 3006: FMJ 90/40/0.5/840/0.0008, M2 AP 85/55/0.6/830
- 338: FMJ 122/47/0.6/900/0.00045, AP 115/79/0.87/849, TAC-X 196/18/0.5/880
Defaults: lbleed 0.15, hbleed 0.05 unless set. Fragmentation (needs pen ≥ 20): +50% damage.

**Weapons** (`class, caliber, mag, rpm, modes, ergo 0-100, kg, recoil up°/side° per shot, MOA, action`):
- m1911 "M1911A1" pistol 45acp, 7, 500, semi, 90, 1.1, 1.6/0.6, 4.5, detachable
- p90 "FN P90" SMG 57x28, 50, 900, semi+auto, 74, 2.6, 0.35/0.25, 3.2, detachable
- ak47 "AK-47" assault rifle 762x39, 30, 600, semi+auto, 50, 3.6, 0.75/0.45, 3.0, detachable
- shotgun "M870" shotgun 12ga, tube 6, pump (cycle ≈0.55 s, anim `FireWBullet`), 55, 3.4, 3.0/1.0, pellet spread 2.2°, loads one shell at a time
- garand "M1 Garand" marksman 3006, 8-round en-bloc (reload only when empty, loads a full clip; empty = clip ejects with a "ping"), 400, semi, 40, 4.3, 1.8/0.7, 1.8
- sniper "AXMC .338" bolt-action 338, 5 detachable, bolt cycle ≈1.1 s, 35, 6.5, 3.5/0.8, 0.6, **6x scope**
Machine guns and grenade launchers are out of scope (no free models).

**Gun handling**
- Fire modes (`t_fire_mode` B). Rate from rpm. Bolt/pump: after each shot the gun must cycle (auto on release; the anim plays) before it fires again.
- **Magazines are objects** holding a stack of rounds (mixed loads allowed) + a separate **chamber**. Reload (R)
  = tactical: swap to a spare mag and keep the old one. Double-tap R = fast reload, which drops the old mag (gone).
  Reload with a round chambered keeps it (+1). Spare mags per weapon come from the defs, refilled at the bench.
- **No ammo counter.** `t_mag_check` (T) shows a Tarkov estimate after ~1 s: "Full / Almost full / About half /
  Less than half / Almost empty / Empty" (exact count for mags ≤ 8). The HUD shows weapon, mode, loaded ammo type and zero.
- Zeroing: `t_zero_up/t_zero_down` (PageUp/PageDown), steps 50/100/200/300/400/500 m (pistol/SMG/shotgun fixed 25/50).
  The launch angle makes the projectile cross the sight line at the zero distance (solve it once per zero by simulation).
- Accuracy: each shot deviates by a random angle within MOA (× ammo factor). Hip fire adds a big cone; ADS removes it.
- Recoil (`recoil_model.gd`): each shot adds up° plus random ±side° to a recoil offset. Sustained auto fire climbs
  to a cap, and the offset converges back at a rate scaled by ergonomics. The camera and the viewmodel both follow.
- ADS (RMB hold): ADS time = lerp(0.45, 0.15, ergo/100) s. The viewmodel moves to a per-weapon `ads_pos` so the
  iron sights sit on screen centre (tune with screenshots). The sniper's 6x scope narrows the FOV and draws a scope overlay (black vignette + mil-dot reticle).
- Sway: an idle breathing sway in ADS, scaled by weight and inverse ergo. Holding `sprint` while ADS = hold breath
  (sway ≈ 0, drains arm stamina, then shaky). Arm stamina also drains while ADS with heavy guns.
- Durability and malfunctions: each shot wears the gun. Chance per shot = base × (1 - durability) + ammo factor.
  Types: misfire (click), failure to feed, jam. The player doesn't know the type until `t_inspect` (L). Press L again
  to fix (takes 1-2.5 s with the anim). Firing while malfunctioned just clicks.
- Stance and movement (`tactical_player.gd`, CharacterBody3D): walk 3.2 m/s, sprint 5.6 m/s (no ADS, no fire),
  crouch (C), lean `t_lean_left/right` (Q/E, camera roll 12° + 0.35 m offset), inertia (acceleration drops with
  weight carried), leg stamina for sprint, jump.

**Damage model (`body_health.gd`)**: zones Head 35, Thorax 85, Stomach 70, LArm 60, RArm 60, LLeg 65, RLeg 65.
Head or Thorax at 0 = dead. Damage to a blacked-out limb spills to every other living zone × (arms 0.7, legs 1.0, stomach 1.5).
Bleeds: light 0.8 HP/s, heavy 2.4 HP/s on the hit zone (spill rules apply). Fracture chance on limbs for hits > 25
(leg fracture slows; arm fracture adds sway). Expose `hit(zone, dmg, info) -> Dictionary` (what happened) and `alive()`.

**Armor (`armor_defs.gd`, `penetration.gd`)**: class 1-6, max durability, material destructibility
(aramid .25, uhmwpe .45, titanium .55, steel .7, ceramic .8), blunt throughput, zones covered.
Rows: Class 2 soft vest (aramid, 50, thorax+stomach, blunt .3); Class 4 plate carrier (ceramic, 50, thorax+stomach, .25);
Class 6 steel plate (steel, 80, thorax, .2); Class 3 helmet (aramid, 30, head, .2, ricochet chance on glancing hits).
Penetration (Tarkov formula): `a = class*10 * (121 - 5000/(45 + 2*dur%)) / 100`. If pen ≥ a then P = 1; if a-15 < pen < a
then P = 0.004*(pen - a + 15)^2; else P = 0. Penetrated: damage × clamp(0.5 + pen/(2a), 0.6, 1.0). Blocked: blunt
damage = dmg × blunt and the bullet stops. Durability loss either way = pen × armor_dmg × destructibility × clamp(pen/a, 0.6, 1.1).

**World materials** (`material_defs.gd`): `resist, ricochet_max_angle°, ricochet_chance, decal colour, sound`.
wood_plank 12; plywood 6; sheet_metal 28 (ricochet ≤ 20°, .5); brick 48; concrete 70; steel_target ∞ (ricochet ≤ 25°, .6);
dirt_berm ∞. Pass if pen × (0.02 m / thick) ... keep it simple: effective resist = resist × thick/0.02 (cap at the material);
pass when pen > effective resist. Passing reduces pen by 60% of resist, damage ×0.75, velocity ×0.8, and deviates 1.5°.
A shallow impact on a ricochet material may reflect instead (velocity ×0.6). Draw a small decal or puff at each impact.

## Firing Range level (`range_layout.gd`, `range_targets.gd`)
Outdoor range at dusk, ~40 m wide and 320 m long, with dirt berms on 3 sides (`dirt_berm`), a concrete floor at the
firing line and grass beyond. A firing booth with a bench, and a **weapon rack** holding all six guns (F `t_use` takes one;
1-6 `t_slot_*` switches between those taken). An **ammo/armor bench**: F cycles the current gun's ammo type and refills
mags; another station cycles the dummy armor (none / class 2 / class 4 / class 6 + helmet) and resets the targets.
- Lanes with distance boards at 10, 25, 50, 100, 200, 300 m.
- Steel plates (10/25/50/100/200/300 m) swing and ring when hit, then reset.
- Paper silhouettes at 25/50 m keep hole marks per zone.
- **Armored dummies** at 15/30/60 m: a mannequin built from boxes/capsules with a hitbox rig, a BodyHealth and the selected
  armor. Floating damage numbers, and a small per-zone panel when hit. They fall when dead and respawn after 4 s.
- **Penetration wall** at 20 m: panels of plywood, wood plank, sheet metal, brick and concrete, each with a dummy behind it.
- **Moving target**: a dummy on a rail at 50 m, 2.5 m/s, back and forth.
- HUD (`range_hud.gd`, use UiTheme/UiKit): no crosshair (Tarkov) except the hip-fire cone dot toggle `t_crosshair` (default off);
  top-left help (`t_help` H toggles); right: weapon, mode, ammo type, zero, mag-check text; left: **hit log** with the last 8
  hits (target, zone, distance m, damage, PEN/BLOCKED/RICOCHET, armor durability left); bottom: player stamina + mini body health.
- Esc: release mouse + a small menu (Resume / Reset range / Quit).

## Phase 4: Kill house + Tarkov-style bots (`scav_bot.gd` etc.)
A walled 30×30 m kill house to the side of the booth (interior walls of plywood/brick, doorways, crates as cover,
5-8 pre-placed cover markers). A terminal spawns 2 Scavs (`t_use`; `--bots` spawns them at start). The bots use the same
module: AK-47 with PS ammo, hitbox rig + BodyHealth (class 2 vest), magazine reloads, ballistics.
- Perception: view cone 110°, range 120 m, LOS raycast to the player's head/thorax. Reaction delay 0.35-1.0 s, longer with
  distance and if the player is still or crouched. Hearing: shots within 150 m, sprint footsteps within 20 m, walking 8 m.
- Brain (state machine): Patrol (waypoints) → Investigate (go to the last noise) → Engage (aim error starts large and shrinks
  the longer it keeps sight, so Tarkov "warm-up" accuracy; bursts on auto under 25 m, semi beyond) → TakeCover when hurt,
  reloading or outgunned (pick the cover marker that breaks LOS, closest first) → Heal in cover below 50% total HP (5 s) →
  Flank (the second bot routes around while the first suppresses the last known position) → Search (last known position, then patrol).
- Move with NavigationAgent3D on a NavigationRegion3D baked from the kill-house geometry at load.
- The bots shoot the player: the player has a hitbox rig + BodyHealth. On death, fade out and respawn at the booth with full health.
- Log state changes in the hit log ("Scav 1: TakeCover").

## Phases (each agent runs at most 2, then stops; next agent resumes from the progress log)
1. **Core module** `scripts/tactical/*` + `range_test.gd` checks (pure logic, works headless): pen-chance edges; 762x39 PS
   zeroed at 100 m hits within 3 cm of the aim point at 100 m; 338 drop at 300 m within 2 cm when zeroed at 300; mag estimate
   strings; tactical vs fast reload; chambered +1; bolt needs a cycle; shotgun fires 8 pellets; Garand reloads only when empty;
   spill and death rules; bleed ticks; plywood passes PS, concrete stops PS, sheet-metal grazing ricochet; malfunction blocks
   fire until inspect + fix. Keybind ids added.
2. **Playable scene**: `scenes/firing_range.tscn`, layout, player, weapons from the rack, viewmodel with the glb clips (fire,
   cycle, reload timed to the action), ADS alignment per weapon, recoil/sway, muzzle flash, Sfx, HUD basics, Esc menu,
   screenshot hook, `tools/range.sh`.
3. **Targets + feedback**: plates, paper, dummies + armor stations, penetration wall, moving target, hit log, floating damage, impact decals.
4. **Kill house + bots** as above, plus `--range-test` checks for the perception (LOS blocked by a wall = not seen) and the brain transitions.

Report per phase (in the log and back to the orchestrator, ≤ 200 words): what was built, tests run with results, anything
skipped or not verified, every file outside `tactical/`/`range/` touched (should only be `keybinds.gd`).
