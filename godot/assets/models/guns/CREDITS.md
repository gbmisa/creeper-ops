# Gun models
- m1911, p90, shotgun, garand, sniper: "Low Poly Animated Guns" by Quaternius, CC0. https://opengameart.org/content/low-poly-animated-guns
- ak47: "Various small arms" by TabascoFriday, CC-BY 3.0 / CC0. https://opengameart.org/content/various-small-arms-assault-rifles-sniper-pistol (Fire/Reload clips and Magazine bone added by us)
Converted with `art/guns_src/export_gun.py`: muzzle along -Z, real length in metres, origin at the bounding-box centre.
- glock18 (Pistol_6), revolver (Revolver_2), mp5 (SubmachineGun_3, stand-in), vector (SubmachineGun_4, stand-in), m4a1 (AssaultRifle2_1): "Ultimate Gun Pack" by Quaternius, CC0. https://opengameart.org/content/ultimate-gun-pack (sources in `art/guns_src/quaternius_ultimate/`)
- mosin: "Various small arms" by TabascoFriday (mosin9130), CC-BY 3.0 / CC0, link above.
- scarh, saiga12, sks, sr25, pkm: generated locally (Krea 2 Turbo + Hunyuan3D 2), CC0-equivalent, ours. Static meshes (no rig/animation), muzzle -Z, origin at the bbox centre. Mount points: `art/gen/mounts.json`.
- FB-E 2026-10-14 replaced the Hunyuan guns (details and URLs: `art/free_src/LICENSES.md`; converted with `art/guns_src/prep_glb.py` + `export_gun.py`):
  - scarh: "Scarh" by AdamKokrito, CC0. saiga12: "Shotgun Auto West" by Pichuliru, CC0. sks: "Rifle West" by Pichuliru, CC0 (battle-rifle stand-in).
  - sr25: "MK14" by austincford, CC-BY 3.0 (stand-in). m4a1: "M4" by Kristian M, CC-BY 3.0 (front post + rear sight; replaces the Quaternius AssaultRifle2_1).
  - m4a1 `rail` and the other four rails in `art/gen/mounts.json` now sit on the receiver top (`measure_gun.py --rail-top`).
- Needs a model: pkm (still generated: no free light machine gun found).
