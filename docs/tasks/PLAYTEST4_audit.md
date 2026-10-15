# Playtest 4 logic audit (Sonnet auditor, read-only, 2026-10-10)

Who can damage what, checked in code on integ. Nothing was run.

## Findings
1. **CONFIRMED: units and Snipers shoot mortars they cannot hurt.** Mortar enemy rows have flash-only `hit` and no `targetable` (hive: `level/enemy_mortar.gd:147`, `:168-174`; enemy-built: `level/enemy_build_crew.gd:105-118`). Units burn ammo, resupply, repeat; a Sniper can lock on forever (`enemy_builder.gd:141`). Fix: `targetable: false` on both rows. -> brief U.
2. **CONFIRMED: player Trebuchet targets hive mortars it cannot kill** (`command/weapon_logic.gd:182-186`, impact `:206-215`). Fix: drop mortars from `_siege_foes` (charge-only rule). -> brief U.
3. **LIKELY: Operative respawn can wait forever.** Cost 100 energy + 25 Salvage, x1.5 per death (`fps/operative_deploy.gd:193-212`); the timer waits until both are payable and Salvage only comes from Salvage Engines. No fallback, no loss condition. **Needs Gregory's call:** cap the growth, or respawn anyway after a wait.
4. Intended: guns only flash a mortar; the charge prompt is accurate. Charges cost Salvage, so item 3 also gates mortar kills.

## Checked and sound
Burrowed Burrower (`targetable` honoured everywhere), Shield Dome (`no_charge`), raider reachability and Lancer line of sight, castle gates/winch/engines, Beam, cannon/mortar/Thor vs creeper, Lance, Deep Core and its hints, level data (`raider_ban`, `ammo_unlock`).

## Not checked
Flyer targeting, enemy-mortar shell line of sight, castle guard `pick`, cave mites, Operative gun targeting.
