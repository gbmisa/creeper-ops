# RANGE5 Track MED progress

## MED-1: status model + med items + use flow (2026-10-14)
Done:
- `scripts/tactical/status_effects.gd` (new): 7 build-up meters 0..1 (pain, radiation, toxication,
  dehydration, energy, fatigue, contusion), warning at 0.5, effect at 1; buff timers (pain_off,
  regen, stim stamina, iodine, tremor, SJ6); `tick(dt, ctx, body)`; effect queries
  (`sway_mult`, `ads_time_mult`, `stamina_regen_mult`, `max_stamina_mult`, `muffle`, `nausea`);
  `apply_med(use, zone, body)` for every item effect; `to_dict`/`from_dict`;
  `zone_candidates`/`pick_zone` for body-part targeting.
- `scripts/tactical/item_defs.gd`: 21 med rows with `use` params (Bandage, Esmarch, Splint, CMS kit
  3 uses, AI-2, Car, Salewa, Grizzly, Analgin 4 uses, Morphine, Propital, SJ6, Adrenaline, eTG-c,
  Iodine, Water, Juice, Crackers, MRE, Combat stim, IFAK). `ItemDefs.make` sets `uses` for meds.
- `scripts/tactical/body_health.gd`: `zone_max()` + `max_mult` (surgery), `heal_pool()` (worst zone
  first), `stop_bleed(zone, kind)`, `surgery()` (blacked limb -> 60 % max).
- `scripts/range/tactical_player.gd`: `status` per player, pain hook on hit, med use flow
  (`use_med` — timed, x0.6 slow, interrupts on sprint/aim/swap), `message` signal, stamina
  regen/max scaled by status.
- `scripts/core/keybinds.gd`: appended `med_quick_1..4` (F5, F6, F7, 0). No renames.
- `scripts/range/inventory_view.gd`: right-click a med emits `use_requested`.
- `scripts/range/inventory_ui.gd`: wires use, zone picker popup for multi-candidate meds, health
  panel in the inventory (zone HP, wound icons, meters), quick-use handling (F5-F7/0).
- `scripts/range/range_hud.gd`: status icons + build-up bars (only when >= 0.5), tunnel-vision
  overlay, med keys in help, player `message` signal connected.
- `scripts/range/player_weapons.gd`: tremor doubles sway; full pain slows ADS x1.3.
- `scripts/range/sound_defs.gd` + `range_audio.gd`: `MEDS` table, `RangeAudio.med(id)`, `med`
  event kind. Placeholder stems; SOUND track replaces samples.
- `scripts/range/range_crate.gd`: meds added to the supply crate loot.
- `scripts/range/skirmish_game.gd`: "meds" loot still heals 0.6 (test) and now also grants an AI-2.
- `scripts/range/scav_bot.gd`: bot Heal finish also stops bleeds (bandage from loot).
- `scripts/range/range_test_med.gd` (new): 40 checks, registered in `range_test.gd`.
Verified:
- Parse clean (no SCRIPT ERROR).
- `--range-test`: OK 570 (baseline 513 + 57 med checks).
- `--smoke --quit=0.1` (RTS main scene): 1263 pass / 1 fail — identical to the integ baseline
  (the fail is the `path perf` timing flake, 180.6 ms vs 470.1 ms on base). A first run showed 2
  extra `attack-move` fails; the isolated `--smoke=attackmove` group passed 7/7 and a full rerun
  came back 1263/1 — order-dependent flakes in RTS combat sims, untouched by this track.
  No new failures vs base.
Open issues:
- Item models are placeholder boxes (world_item.gd); Opus makes the Hunyuan models.
- Contusion "blur" is a HUD overlay, not a real blur shader; audio muffle is exposed via
  `status.muffle()` for the SOUND track to wire.
- Radiation hot zone: `player.in_hot_zone` defaults false; the skirmish radar hill needs to set it
  (left for EXPAND/LOOK or a follow-up).
