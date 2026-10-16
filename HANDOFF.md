# Handoff: 2026-10-16 (Opus, branch feat/fb-reload, main checkout)

## This session (uncommitted until the commit below; the 3 `reload_*.gd` files were already dirty, not touched)
1. **P9 arm loss (APPROVED, built)**: `TacticalConfig.ARM_LOSS`, `BodyHealth.arms_down/arm_loss/can_hold_breath`.
   Player: sway, ADS time, recoil (`RecoilModel.shoot` strength), reload time (busy_t, the animation follows), no breath
   hold. **Bots too** (Gregory): aim spread x sway, reaction x ads, reload x reload. HUD: red line beside the body figure.
2. **Meds + quick-use bar**: Skirmish crate "meds" now gives `ItemDefs.CRATE_MEDS` (IFAK + bandage) into the
   inventory (drops at your feet if full) instead of healing on the spot. `QuickUse` (range/quick_use.gd): keys 4 / 5
   (`t_slot_4/5`, relabelled "Quick use"), IFAK 3 s heal 60 % + stops bleeds, bandage 2 s stops bleeds; hands busy =
   no fire/ADS. `QuickBar` (range/quick_bar.gd) = the build-menu panel + BuildCards (BuildCard got an optional glyph arg).
3. **Skirmish MAP-2 layout**: plan + map in `docs/tasks/SKIRMISH_MAP2.md`. West = CQC old town (9 buildings, alleys,
   sniper street to the tower), east = open with barracks + warehouse and spaced cover. New cover kind `container`.
   `SkirmishLayout` inner walls now support axis "x" (offset bug fixed; the barracks "z" wall is unchanged).
4. CHANGES.md: P9 ruled; new **P10** (bots ignore leg damage; slow on blacked legs?) and **P11** (arm fracture sway is
   dead code).

## Verified
- Parse clean. `--range-test`: everything I added passes (P9, quick use, loot, 6 `map2` checks, F93). Screenshots
  (Vulkan, real display) judged by Opus: overview, tower view down the street, alley, east field, quick bar.
- Not verified: Gregory's play, bot behaviour over a full match on the new map, perf with 9 more buildings and lights.

## Test failures (4) and why
- `navmesh routes through the doorways to the far room` (kill house) fails in this checkout **before my changes too**
  (baseline copy). When it fails, two roster checks that reuse the kill house can fail as well (shotgunner closes in,
  boss followers).
- `a shot at spawn: every bot ... moves within 4 s (F88)`: Scav 5 runs 6.6 m to cover, then walks back on Search, so
  its *net* move is 0.6 m. It isn't stuck: the check measures net distance. The new cover list changed which cover it
  picks. Check left as is (rule: report, don't loosen).
- `ReloadTimeline._anchor` 'lock' script errors come from the uncommitted reload WIP files, not this work.

## Known issues (pre-existing, not fixed: outside the ask)
- Barracks navmesh: the north door (x 24-26) is split by the inner wall at x 25 (two 0.9 m halves, too narrow for a
  bot), and paths into the east room / warehouse end ~2 m short (map2 probes; same on the old map).
- Older items: see git history of this file (integ worktree, perf probe, CHANGES 1-15 rulings).

## Next
1. Gregory plays Skirmish MAP-2 and rules on CHANGES P10 / P11.
2. If wanted: fix the barracks door / navmesh gaps, rooftop routes, container visuals.
