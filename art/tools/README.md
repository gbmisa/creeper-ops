# Local 3D generation (ComfyUI on :8188, RTX 5090)
1. `python3 art/tools/gen3d.py --prompt "olive military ammo crate" --out art/gen/crate` (or `--image concept.png`).
   Krea 2 Turbo concept image -> Hunyuan3D v2 (`~/ComfyUI-models/checkpoints/hunyuan3d-dit-v2.safetensors`) -> raw GLB.
   ~40 s. Writes `<out>.png` + `<out>.glb` (~360k tris, untextured). Rename the raw mesh `*_raw.glb` (gitignored).
2. `blender -b --python art/tools/glb_cleanup.py -- raw.glb game.glb --tris 2500 --size 0.75 --concept concept.png`
   voxel remesh + decimate, origin bottom centre, longest side = size m, flat colour from the concept.
3. `blender -b --python art/tools/glb_preview.py -- game.glb preview.png` clay render + tri count.
Limits: no texture (Hunyuan paint isn't in ComfyUI core yet); no rig: characters keep the Quaternius rig.
4. Textured, oriented, game-ready (guns, sights, attachments, utility): `gen3d.py ... --side` (strict side profile concept),
   `glb_cleanup.py ... --auto-orient --origin center|bottom|top|back --concept c.png` (long axis -> muzzle -Z, direction matched to the
   concept's silhouette; `--rotate x,y,z` / `--flip` override, Blender axes), then
   `blender -b --python art/tools/glb_texture.py -- clean.glb out.glb --concept c.png` (planar projection along the thin axis,
   1024 texture, flat patch for grazing faces; `--thin y --right x` for upright round items).
   Batch drivers: `gen_batch.py` (all Range 5 prompts), `build_models.py` (cleanup+texture into `godot/assets/models/`),
   `contact_sheet.py out.png`, `mounts_probe.py` (gun mount points -> `art/gen/mounts.json`, `--render dir` draws them).
   `glb_preview.py in.glb out.png [3q|side|side2|top]`.
