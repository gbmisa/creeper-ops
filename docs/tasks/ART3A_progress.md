# ART3 A progress: creature animation runtime (branch `art/3-creature-anim`)

## Done
- New `godot/scripts/level/creature_anim.gd` (`class_name CreatureAnim`): `id_of`, `make(id, scale, glow)` (null when no `.glb`; caches PackedScenes), `move` (walk/idle blend, speed_scale = speed/1 m/s, never stomps attack/hit/die one-shots), `attack`, `hit` (re-trigger safe), `die(node, then)` (plays die, calls then on finish; at once with no clip; DIE_MAX 1.5 s failsafe). "glow"-named materials replaced with the caller's glow.
- Hooks: `RaiderMeshes.make` (+ new `anim_scale` matching the procedural tier.size*k, Sentinel fixed 1.0), `FlyerMeshes.make` (id `spore_bat`/`gasbag`/`wyvern`, scale = size), `UnitMeshes.make` (id `soldier`/`crawler`, scale 1.0), `HiveMeshes.part("core")` (id `core`, scale 1.0) — all try `CreatureAnim.make` first, procedural fallback otherwise.
- Behavior hooks: `raiders.gd` `_walk` -> move, `_think` melee -> attack, `hit` closure -> hit (survivors only); `Raiders.kill` removes targeting/collision at once, frees the node after `die` (immediate with procedural fallback). `flyers.gd` `fly` -> move, `hurt` -> hit; `flyer_ai.gd` `_bite`/`_breath` -> attack. `unit_manager.gd` `_move` -> move, `damage` -> hit; `unit_supply.gd` fire -> attack.
- `--gallery=anim` (new mode on the existing `--gallery` hook): `level/creature_gallery.gd` lays every creature id in a row with Label3D labels, cycles clips every 2 s via an inner Driver node. Documented in `debug.gd`.
- Smoke: new `core/smoke_creature_anim.gd` (registered in `smoke_test.gd`): no-.glb fallback for all ids/tiers/flyers/units/core, hook no-ops, clip logic on a hand-built animated node (glow swap, walk 3x, idle, attack/hit, no stomp, die defer + finish, immediate with no clip), raider kill path (node freed, target dropped, list erased).

## Decisions (spec silent)
- `--gallery=anim` is a *mode* of the existing `--gallery` flag, not a new flag: `--gallery` was already taken by the structure/unit/raider art rows.
- Flyer attack hooks live in `flyer_ai.gd` (`_bite`, `_breathe`) and the unit attack hook in `unit_supply.gd`: `flyers.gd`/`unit_manager.gd` contain no attack events to hook.
- Sentinel is not in `RaiderDefs.ROWS`; the gallery and smoke build its dict inline (same as the old gallery).
- `sentinel` cannot be a GDScript variable name in 4.7.2 (parser rejects it); renamed to `sent`.
- Godot 4 has no `AnimationPlayer.add_animation` (animations live in `AnimationLibrary`); the smoke test builds its fake player with an AnimationLibrary.
- No test `.glb`: fabricating an importable glb at runtime isn't possible (import pipeline), so the smoke test exercises the identical wrap path on a hand-built AnimationPlayer node instead.

## Verified
- Parse: clean (no SCRIPT ERROR) with Godot 4.7.2-stable headless.
- Smoke `--smoke=creature`: 19/19 PASS (no-.glb fallback, hook no-ops, glow swap, walk/idle blend at 3x, attack/hit one-shots, no-stomp, die defer + finish + immediate-without-clip, raider kill path).
- Full smoke suite: 723/724 PASS. The single FAIL was the castle-garrison check documented as flaky in LONG_RUN_RULES.md ("flakes ~1 in 10"); a full re-run passed it, confirming it's the known flake and unrelated to this branch (no SCRIPT ERRORs anywhere; the check exercises castle gate pathing, untouched here).
- (Opus: no `.glb` files exist yet, so the model path is code-reviewed only; `--gallery=anim` is ready for your screenshots once you export.)

## Suggestions
- `Raiders.kill` callers in `castle_raids.gd`/`stronghold` code assume instant removal from `list` — still true (erased before the anim), but anything holding `r.node` across a kill should be audited when models land.
- Consider a `walk`/`idle` crossfade (currently a hard switch) if Opus's clips pop on transitions.
