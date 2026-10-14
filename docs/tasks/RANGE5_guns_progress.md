# RANGE5 GUNS progress

## GUNS-1 (done): roster + ammo + mags + tests
- 11 new rows in `weapon_defs.gd` (17 total, `ORDER`); all rows got `tier`, `unlock`, `role`, `slots`. Existing six keep their numbers.
- Models: rows carry `model_fallback` (+ `fb_flip`); `WeaponDefs.of()` swaps `model`/`flip` to the fallback until `assets/models/guns/<id>.glb` exists, so all callers are unchanged. View data (ads/hip/grip/mag_l/butt) is copied from the fallback row: GUNS-2/ART replace with mounts.json.
- Ammo: new calibres 9x19, 44mag, 556x45, 762x51, 762x54r (3 grades each) in `ammo_defs.gd`; `ROUND_KG`/`STACK_MAX` in `item_defs.gd`. Mags: `mag_<id>` for every new gun (revolver = speedloader, pkm = 100-rd belt box). Revolver is `enbloc` (6 rounds total, reload only when empty); PKM mag 100 (+1 chambered).
- Rack: grid rows = lines, columns = tiers; label = name [Tn] + role. Crate: 11 new mags + 5 ammo stacks (COLUMNS 8 -> 12).
- Tests: `range_test_guns.gd` (called from `range_test.gd`); `--range-test` OK 396 (was 211).

## Key numbers (id: tier, cal, mag, rpm, up/side, moa, ergo, kg, reload, default ammo dmg/pen)
| id | t | cal | mag | rpm | up/side | moa | ergo | kg | reload | dmg/pen |
|---|---|---|---|---|---|---|---|---|---|---|
| m1911 | 1 | 45acp | 7 | 500 | 1.6/0.6 | 4.5 | 90 | 1.1 | 2.0 | 72/25 |
| glock18 | 2 | 9x19 | 17 | 1100 auto | 2.4/1.1 | 5.5 | 88 | 0.9 | 1.9 | 54/20 |
| revolver | 3 | 44mag | 6 | 120 | 4.5/1.2 | 3.5 | 70 | 1.5 | 5.0 | 135/14 |
| mp5 | 1 | 9x19 | 30 | 800 | 0.30/0.20 | 2.2 | 72 | 2.9 | 2.5 | 54/20 |
| p90 | 2 | 57x28 | 50 | 900 | 0.35/0.25 | 3.2 | 74 | 2.6 | 2.8 | 49/37 |
| vector | 3 | 45acp | 25 | 1100 | 0.18/0.12 | 3.8 | 78 | 2.7 | 2.2 | 72/25 |
| ak47 | 1 | 762x39 | 30 | 600 | 0.75/0.45 | 3.0 | 50 | 3.6 | 3.0 | 57/35 |
| m4a1 | 2 | 556x45 | 30 | 800 | 0.50/0.30 | 2.0 | 62 | 3.2 | 2.6 | 49/37 |
| scarh | 3 | 762x51 | 20 | 600 | 0.85/0.45 | 1.8 | 45 | 4.4 | 3.2 | 74/53 |
| shotgun | 1 | 12ga | 6 | 120 | 3.0/1.0 | 10 | 55 | 3.4 | 0.9/shell | 39x8/3 |
| saiga12 | 2 | 12ga | 8 | 240 | 2.6/0.9 | 9 | 52 | 3.6 | 3.2 | 39x8/3 |
| sks | 1 | 762x39 | 10 | 360 | 1.5/0.6 | 2.4 | 45 | 3.9 | 2.8 | 57/35 |
| garand | 2 | 3006 | 8 | 400 | 1.8/0.7 | 1.8 | 40 | 4.3 | 2.6 | 90/40 |
| sr25 | 3 | 762x51 | 20 | 450 | 1.2/0.5 | 1.0 | 55 | 4.5 | 2.8 | 74/53 |
| mosin | 1 | 762x54r | 5 | 50 bolt 1.3 | 3.2/0.9 | 1.6 | 38 | 4.0 | 3.8 | 86/42 |
| sniper | 3 | 338 | 5 | 60 bolt 1.1 | 3.5/0.8 | 0.6 | 35 | 6.5 | 3.2 | 122/47 |
| pkm | 3 | 762x54r | 100 | 650 auto | 0.90/0.60 | 3.8 | 25 | 8.4 | 7.0 | 86/42 |
Unlock levels: m1911 1, mp5 1, ak47 1, shotgun 2, sks 3, mosin 6, p90 6, glock 8, garand 8, m4a1 10, saiga 12, sniper 18, revolver 20, vector 22, sr25 24, scarh 25, pkm 28.

## Notes for GUNS-2
- `slots` are string lists (sight/muzzle/under/mag); m4a1, scarh, sr25, vector have all four.
- Real glb arrival: `fb_flip` is dropped automatically; view data for new guns is still the fallback's.
