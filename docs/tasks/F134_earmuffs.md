# F134: Tarkov-style earmuffs (headset slot) (Gregory ruled 2026-10-16: Tarkov-style)
Branch feat/f134-earmuffs, worktree ../f134. Base play/f98-f107.
## Build
1. New equip slot "headset" (Inventory.SLOTS, slot rule kind "headset", InventoryView SLOT_CELLS 2x1 + title,
   placed beside the HELMET slot on the same row; keep the column fitting a 900 px window). Worn with any helmet.
2. Item `headset_comtac` (ItemDefs, kind "headset", 2x1, ~0.5 kg, name "Comtac earmuffs"). One in RangeCrate.LOOT
   and in Skirmish loot tables (both maps) at low weight.
3. While worn: bot footsteps (BotSteps) +8 dB and heard 1.5x further; other quiet sounds (bot voice/reload/mech
   if any 3D) +4 dB; gunshots + explosions (player and bots, 3D and 2D) compressed: -8 dB. Simplest route: one
   static `HearingMods` helper read where those sounds set volume_db; values in a def table.
4. Inventory to_dict/from_dict carry the slot (kit-persist into Skirmish, Restart reload) and the death/KIA path.
## Don't change
Helmet/armor protection, any sound with earmuffs off, keybinds, other slots' layout beyond making room.
## Done
Parse clean, range + Skirmish boot with no new SCRIPT ERROR; one small test in a new range_test_headset.gd (slot
accepts only headset, survives to_dict/from_dict, volume mods on/off). Range suite once (background, summary only;
known FAIL f127). Commit on your branch. Report under 200 words.
