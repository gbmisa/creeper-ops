# Brief FB-C: Firing Range + Operative fixes (F6, F7-F11, F15, F20, F22, F23)
Source: `docs/playtests/feedback_2026-10-14.md` (main repo). Branch `fix/fb-c-range`.
Base: `integ/2026-10-09` after `feat/mp1` merges (else `origin/feat/mp1`). Agent: Muse or Sonnet `feature-dev`, 2 phases max.
Read `AGENTS.md`, this brief, the files you change. **Change only what each item names.**

## Phase 1: bugs
- **F20 gun invisible after a state change.** Deploying to the skirmish or returning to the range shows no gun until a
  weapon swap. The held gun's viewmodel must be visible right after every transition (`range/player_weapons.gd`
  `select_slot`/`sync`, `tactical_viewmodel.gd`, `range_truck.gd`). Test both transitions.
- **F6 restart resets the loadout.** Skirmish restart (`skirmish_end.gd`) must keep the deployed loadout. Nothing else about
  restart changes.
- **F22 shotgun can't reload at the bench.** The M870 is `"action": "tube"` (`tactical/weapon_defs.gd:29`). The ammo bench
  (`range/range_bench.gd`) must give 12ga shells, and the shotgun reloads one shell at a time into the tube. UI says
  "tube"/"shells", never "magazine", for tube guns. Don't change other guns' magazines, ammo amounts or shotgun stats.
- **F23 sprint-jump drops to walk speed.** `tactical_player.gd:154` requires `is_on_floor()` for sprint, so jumping drops to
  `WALK`. Keep the take-off sprint speed through the air until landing. Jump height, speeds and stamina stay the same.
- Tests for each of the four.

## Phase 2: range stations
- **F9** ammo bench: move it against the wall; flip its text to face the player.
- **F10** armour station: flip its text; the armour sits on/in the station, not on the ground in front.
- **F8** ammo has no world model, only an inventory icon (ammo comes from the bench).
- **F7** ground pickups are invisible. Show a model per item: use the free models from FB-E when they exist, else a
  labelled placeholder box sized to the item's grid size. Don't make new models.
- **F15** meds box does nothing. First check `origin/feat/r5-med`: if it already opens a loot screen, skip this and say so.
  Otherwise opening it shows the inventory loot screen (`inventory_ui.gd`) with its contents.
- **F11** workbench: a range station where all weapon customization happens (attachments via `AttachmentRig`). Use the
  existing attachment data; placeholder bench mesh. If it needs more than ~150 lines, stop after a plan and report.
- Must not change: weapon stats, ammo amounts, range layout beyond the moves above.

## Done
Parse clean, `--range-test` all PASS, main `--smoke` 0 FAIL. Push, report every behaviour change, stop.
Opus judges the station screenshots.
