# Stage 10a: Armoury (Operative upgrades + advanced weapons)

**Agent:** Grok Build (Sonnet-class). **Worktree:** `creeper fps td-worktrees/stage10a` · **Branch:** `stage/10a-armoury`
Spec: [STRONGHOLDS_DESIGN.md](../STRONGHOLDS_DESIGN.md) §5.2 (upgrades, advanced weapons). Runs alongside Opus's **7b** (castle raids), Grok's **7c** (Level 1 terrain) and Grok's **11a** (Terp).
**Stay out of:** `level/*` (all of it), `command/packets.gd`, `command/packet_requests.gd`, `command/structure_defs.gd`, `command/command_*.gd`, `shaders/*`, `world/*`. **Not in this stage:** improved ammo grades, Ctrl + wheel switching, the Pack upgrade (extractors don't exist yet), the castle Armoury (Opus wires it into castles at merge; just expose an API it can call).

## Why
Salvage now comes in (castle trickle + capture bonus) but the Operative has nothing to spend it on except respawns. The Armoury makes Salvage a choice: a stronger Operative versus castle turrets.

## Do
1. **`fps/operative_upgrades.gd`** (`class_name OperativeUpgrades`, static, same shape as `command/upgrades.gd`): a `DEFS` table + `ORDER`, `reset()`, `level(id)`, `cost(id)`, `maxed(id)`, `mult(id)`, and `buy(id, stockpile: Stockpile) -> String` ("" on success, else why). Costs are per tier from the table, not base+step. Rows (§5.2):
   - `firepower` 3 tiers, 20/45/80: rifle damage +25% per tier, rocket magazine +1 per tier.
   - `armour` 3 tiers, 20/45/80: suit max +25% per tier; tier 3 adds a 30-point shield that absorbs damage first and regenerates after `REGEN_DELAY`.
   - `mobility` 3 tiers, 15/35/70: sprint +10% per tier; tier 2 double jump; tier 3 jump jet (holding jump in the air gives enough lift to reach **one more terrace** than a double jump).
   - Unlocks for the three advanced weapons (one-off, `unlock_<id>`), costs below.
   Every number lives in this table. Weapon and controller code reads `OperativeUpgrades.mult()` / `level()`, never the raw table. Call `reset()` next to `Upgrades.reset()` in `game_flow.gd`. Upgrades and unlocks **survive death** (level-wide).
2. **`fps/advanced_weapons.gd`** (keep `operative_weapons.gd` under 250 lines; move code out of it if needed). Slots 4/5/6, usable only once unlocked, burning Salvage from the `Stockpile`:
   - **Railgun** (unlock 60, 2 Salvage per shot): 1.5 s charge while the trigger is held, then 30 damage that **pierces** every target sphere on the ray (world.targets + prey-style raiders the rifle already hits), up to `RIFLE.range`.
   - **Plasma thrower** (unlock 60, 1 Salvage per second of firing): a cone like the Null Sprayer but removing creeper at 3× the rocket's rate, plus 6 dps to targets in the cone.
   - **Demolition charge** (unlock 40, 8 Salvage each): thrown arc ~20 m, sticks where it lands, explodes after 2 s for 120 damage to targets within 2 cells. It **must not damage** the Deep Core (check how `fps/cave_hazards.gd` marks it, and skip it).
   With no Salvage the weapon clicks (`Sfx "deny"`) and the HUD says why. New actions `adv_railgun`, `adv_plasma`, `adv_demo` in `Keybinds.DEFAULTS` (Operative group, keys 4/5/6). Check `~/.local/share/godot/app_userdata/Creeper Ops/keybinds.cfg` first if it exists; never rename an existing action.
3. **Where you buy:**
   - **Command mode:** the Command Node's info panel (`ui/info_panel.gd`, `s.type == "node"`) lists Armoury buttons like the Forge does (label, tier, Salvage cost). If that pushes `info_panel.gd` past ~200 lines, put the rows in a new `ui/armoury_menu.gd` and call it from there.
   - **First person:** an interactable at the Command Node ("[E] Armoury"). It opens a small overlay listing the same rows. The mouse is released while it's open, it closes on Esc or E, and it buys on click. Reuse the same row builder as the command panel.
   - Expose `ArmouryMenu.open(fps, stockpile)` (or similar) so a held castle can open it later. Write in your report how to call it.
4. **HUD** (`ui/fps_hud.gd`): shield bar when it exists, Salvage count while an advanced weapon is out, railgun charge, "Need N Salvage".
5. **Debug hooks** in `core/debug.gd`: `--salvage=N` already exists; add `--armoury=id[,id...]` (buys those for free at start, for screenshots).

## Checks: new `core/smoke_armoury.gd`, registered with one line in `smoke_test.gd`
- Buy fails without Salvage, succeeds and spends with it, stops at max tier; `reset()` clears it.
- Firepower 1 raises rifle damage by 25%; rocket magazine +1. Armour raises suit max; tier 3 shield soaks damage before the suit.
- Mobility: a scripted `PlayerController` jump at tier 0 cannot reach a ledge that tier 2 (double jump) can; tier 3 reaches one level more than tier 2.
- Railgun pierces two targets in a line; plasma removes creeper faster than the sprayer; a demolition charge hurts a target in range and not the Deep Core.
- Firing an advanced weapon burns Salvage; with 0 Salvage it doesn't fire.
- Upgrades survive a death/respawn (`smoke_deploy.gd` shows how to kill the Operative).

## Verify
Parse check, full smoke (all PASS, report the count), `--demo --units --sim=900` (Node HP unchanged vs `main`). Xvfb screenshots: the first-person Armoury overlay at the Node, and one advanced weapon firing (`--armoury=...` + `--salvage=200`).

## Report (AGENTS.md)
Files, every new tunable, test output, screenshot paths, how a castle should call the Armoury, anything unsure. Set Stage 10 to "⚠ 10a" in MASTER_PLAN.md and add one Changelog line. Don't edit HANDOFF.md.
