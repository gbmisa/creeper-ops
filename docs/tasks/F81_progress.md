# F81 progress log

## P1 (2026-10-16): NOT REPRODUCIBLE through the real path
Repro: `godot/scripts/range/range_test_f81.gd` (`RangeTestF81.run` + `.fuzz`, wired in range_test.gd). Real RangeSession (map left at
default "range", infinite NOT forced), PlayerWeapons.setup with StarterLoadout, every WeaponDefs.ORDER gun, real R presses via
PlayerWeapons._process, 10 cycles each (empty / partly fired / double-tap R mid-animation; tubes one press per shell), plus a 60-step
fuzz per gun (fire, R, double R, slot switch, menu open, bench ammo change + refill, settle) ending in one clean R.
Also drove the live firing_range scene with real KEY_R InputEvents (ak47, garand held; shotgun/sniper/pkm go to the pack, see below).
Result for every gun: infinite=true, ammo_pick valid (first grade), staged=false, spares empty, mag full (detachable: cap-1 + chamber).
Suspects: 1 (infinite false) no; 2 (empty ammo_pick, fresh kit) no; 3 (stale staged) no, incl. switch/menu/bench; 4 (double tap) no; 5 not tested.
Not tested: gun kit restored from saved_kit, attachments, malfunction clicks, trigger held through R.
Behaviours that look like "dry" but are by design today: Garand R is refused while any round is in the clip; shotgun/bolt R is
refused while needs_cycle; a malfunction click ("misfire/feed/jam") fires nothing and R does not clear it; a 4th gun picked from the
rack goes to the pack, not the hand (3 hand slots).

## P2: not started (no confirmed cause).
