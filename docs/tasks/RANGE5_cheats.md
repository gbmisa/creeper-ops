# Brief: secret Tempest weapon (Ctrl+Alt+P) + debug cheat menu (Ctrl+Numpad 5)
Branch `feat/r5-cheats` from integ at this brief. Firing Range + Skirmish only (tactical scenes); main game untouched.
Gregory (2026-10-14): "Create a secret power weapon that can be activated with the keybind control alt p. Do not list this
in the controls." / "Create a list of real in-game cheats they can be activated by pressing control and 5 on the
numpad for debug purposes."

## Hidden chords (not in the Controls screen, not rebindable)
`Keybinds.HIDDEN := {"secret_tempest": [ctrl+alt+P], "cheat_menu": [ctrl+KP_5]}` (store as keycode | modifier mask).
`InputState._input` also records the chord code when Ctrl/Alt are held; `InputState.act_hidden(id)`. Nothing in
`DEFAULTS`, so `keybind_menu.gd`, `Keybinds.fill/short`, the help panel and `user://keybinds.cfg` never see them.
Never touch `user://keybinds.cfg`; tests set `Keybinds.persist = false`.

## Tempest (secret power weapon)
- Row kept out of `WeaponDefs.ORDER`, the rack, crates and loot (e.g. `scripts/tactical/secret_arms.gd`, looked up
  by `WeaponDefs.of`). Railgun: full auto 600 rpm, 200-round cell, no recoil/sway, flat trajectory (v0 2500 m/s, no
  drag), pen 100 (through walls via the existing penetration model, through any armor), damage kills any zone,
  electric-blue tracer + impact sparks + a short chain-lightning arc to bots within 4 m of the impact.
- Ctrl+Alt+P toggles: puts Tempest in the hand (current gun goes to the stash/backpack or is restored on toggle off;
  nothing is lost). HUD shows only "TEMPEST".
- Model: Hunyuan (`art/tools/README.md`), "futuristic compact railgun, glowing blue coils"; sound: new profile in
  `sound_defs.gd` (pitched-up .338 crack + electric zap).

## Cheat menu (Ctrl+Numpad 5)
A debug panel (mouse visible, game keeps running; the same chord closes it) with buttons, each a real, working
toggle/action, state shown ON/OFF:
1 God mode (no damage, no bleeds/fractures) · 2 Infinite ammo (no reload needed) · 3 No recoil + no sway ·
4 Noclip fly (WASD + Space/Ctrl, 3x speed, no collision) · 5 Infinite stamina · 6 Full heal (all zones, clears
bleeds/fractures) · 7 Kill all bots · 8 Freeze bot AI · 9 Invisible to bots · 10 Spawn bot (kind cycles rifleman /
pistol / shotgunner / marksman / boss) at the crosshair · 11 Give every gun + attachment (into a ground crate at the
player) · 12 Teleport to crosshair · 13 Teleport to extract (Skirmish) · 14 Instant extract (Skirmish) · 15 Time
scale 0.25 / 1 / 2 · 16 Show bot debug (state label + view cone) · 17 Show hitboxes · 18 Show navmesh · 19 FPS/perf
overlay · 20 Reset range/map.
Using any cheat sets `cheats_used` on the session; the Skirmish end screen shows "CHEATS USED". Multiplayer
(docs/MULTIPLAYER.md): cheats are per-player state, allowed only offline or for the host; route each through one
request function.

## Tests + checks
One `[range] PASS` check per cheat proving its effect, plus Tempest (hidden from ORDER/rack/keybind menu, chord gives
and removes it, rail round penetrates a wall and kills a plate-armored dummy) and "hidden chords not in DEFAULTS".
Parse clean, `--range-test` all PASS (currently 513), main smoke 0 FAIL. One Vulkan screenshot of the cheat panel and
one of Tempest firing.
